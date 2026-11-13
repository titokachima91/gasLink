/**
 * GasLink Firebase <-> SMS/AI gateway bridge.
 *
 * Secure, read-mostly API for the self-hosted Node gateway. Mount behind the
 * same `x-api-key` tenant key used by /v1/send-sms.
 *
 *   GET  /subscriber?phone=+2557...
 *   GET  /catalog
 *   POST /orders
 *   GET  /health
 *
 * The module is intentionally standalone: it can be mounted into the existing
 * gateway (app.use('/v1/bridge', createFirebaseBridgeRouter())) or run with
 * gateway/server.js on its own port.
 */

const crypto = require('crypto');
const path = require('path');
const express = require('express');
const admin = require('firebase-admin');

const DEFAULT_PROJECT_ID = 'gaslink-app-4bfbb';

const BRAND_COLORS = [
  { brand: 'Oryx Gas', match: /oryx/i, color: 'Red', aliases: ['red', 'nyekundu'] },
  { brand: 'Manjis / Mihan Gas', match: /mihan|manjis/i, color: 'Yellow', aliases: ['yellow', 'njano'] },
  { brand: 'Taifa Gas', match: /taifa/i, color: 'Blue', aliases: ['blue', 'bluu'] },
  { brand: 'O-Lake / Lake Gas', match: /lake/i, color: 'Green', aliases: ['green', 'kijani'] },
];

function brandColor(brand) {
  const found = BRAND_COLORS.find((entry) => entry.match.test(brand || ''));
  return found
    ? { color: found.color, aliases: found.aliases }
    : { color: null, aliases: [] };
}

function normalizePhone(raw) {
  const value = String(raw || '').replace(/[\s\-()]/g, '').trim();
  if (!value) return '';
  const withoutPlus = value.startsWith('+') ? value.slice(1) : value;
  if (/^0\d{9}$/.test(withoutPlus)) return `+255${withoutPlus.slice(1)}`;
  if (/^[67]\d{8}$/.test(withoutPlus)) return `+255${withoutPlus}`;
  if (/^255[67]\d{8}$/.test(withoutPlus)) return `+${withoutPlus}`;
  return value.startsWith('+') ? value : `+${value}`;
}

function isValidTzPhone(phone) {
  return /^\+255[67]\d{8}$/.test(phone);
}

function phoneVariants(phone) {
  const normalized = normalizePhone(phone);
  const digits = normalized.replace('+', '');
  const local = `0${digits.slice(3)}`;
  return [...new Set([normalized, digits, local])];
}

function safeEqual(a, b) {
  const left = Buffer.from(String(a || ''));
  const right = Buffer.from(String(b || ''));
  if (left.length !== right.length) return false;
  return crypto.timingSafeEqual(left, right);
}

function ensureFirebaseApp() {
  if (admin.apps.length) return admin.app();

  const credentialsPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (credentialsPath) {
    // eslint-disable-next-line import/no-dynamic-require, global-require
    const credentials = require(path.resolve(credentialsPath));
    return admin.initializeApp({
      credential: admin.credential.cert(credentials),
      projectId: credentials.project_id || DEFAULT_PROJECT_ID,
    });
  }

  return admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: process.env.FIREBASE_PROJECT_ID || DEFAULT_PROJECT_ID,
  });
}

function subscriberResponse(subscriber) {
  if (!subscriber) {
    return {
      exists: false,
      registered: false,
      found: false,
      aiAssistantEnabled: false,
      aiEnabled: false,
    };
  }
  return {
    exists: true,
    registered: true,
    found: true,
    aiAssistantEnabled: subscriber.aiAssistantEnabled,
    aiEnabled: subscriber.aiAssistantEnabled,
    uid: subscriber.aiAssistantEnabled ? subscriber.uid : undefined,
    name: subscriber.aiAssistantEnabled ? subscriber.name : undefined,
    channel: subscriber.channel,
  };
}

function createFirebaseBridgeRouter(options = {}) {
  const apiKey = options.apiKey || process.env.API_KEY_GASLINK;
  const router = express.Router();

  router.use((req, res, next) => {
    if (!apiKey) {
      return res.status(500).json({
        error: 'Server misconfiguration',
        message: 'API_KEY_GASLINK is not set',
      });
    }
    if (!safeEqual(req.headers['x-api-key'], apiKey)) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid or missing x-api-key',
      });
    }
    next();
  });

  function db() {
    ensureFirebaseApp();
    return admin.firestore();
  }

  async function findSubscriber(phone) {
    const firestore = db();
    const snapshot = await firestore
      .collection('users')
      .where('phone', 'in', phoneVariants(phone))
      .limit(1)
      .get();
    if (snapshot.empty) return null;
    const doc = snapshot.docs[0];
    const data = doc.data() || {};
    return {
      uid: doc.id,
      phone: normalizePhone(data.phone || phone),
      name: (data.name || '').toString(),
      role: (data.role || '').toString(),
      aiAssistantEnabled: data.ai_assistant_enabled === true,
      channel: (data.notification_channel || 'both').toString(),
    };
  }

  async function findProduct(vendorId, brand, size, category) {
    const firestore = db();
    const filter = (data) => {
      const dataBrand = (data.brand || '').toString().toLowerCase();
      const dataSize = (data.size || data.weight || '').toString().toLowerCase();
      const dataCategory = (data.category || 'refill').toString().toLowerCase();
      return (
        dataBrand === brand.toLowerCase() &&
        dataSize === size.toLowerCase() &&
        (!category || dataCategory === category.toLowerCase())
      );
    };

    const top = await firestore
      .collection('products')
      .where('vendor_id', '==', vendorId)
      .get();
    let topMatch = top.docs.find((doc) => filter(doc.data() || {}));
    if (!topMatch) {
      const topCamel = await firestore
        .collection('products')
        .where('vendorId', '==', vendorId)
        .get();
      topMatch = topCamel.docs.find((doc) => filter(doc.data() || {}));
    }
    if (topMatch) {
      return { id: topMatch.id, ref: topMatch.ref, data: topMatch.data() || {} };
    }

    const legacy = await firestore
      .collection('vendors')
      .doc(vendorId)
      .collection('products')
      .get();
    const legacyMatch = legacy.docs.find((doc) => filter(doc.data() || {}));
    if (legacyMatch) {
      return {
        id: legacyMatch.id,
        ref: legacyMatch.ref,
        data: legacyMatch.data() || {},
      };
    }
    return null;
  }

  async function vendorMap() {
    const firestore = db();
    const snapshot = await firestore.collection('vendors').limit(500).get();
    const map = new Map();
    snapshot.docs.forEach((doc) => {
      const data = doc.data() || {};
      const status = (data.status || '').toString().toLowerCase();
      const active = data.active !== false;
      if (!active || status === 'suspended' || status === 'rejected') return;
      map.set(doc.id, {
        id: doc.id,
        name: (
          data.businessName ||
          data.business_name ||
          data.shop_name ||
          'Muuzaji Gesi'
        ).toString(),
        area: (data.areaText || data.ward || data.district || '').toString(),
        verified: data.verified === true,
        status: status || 'active',
      });
    });
    return map;
  }

  router.get('/health', (req, res) => {
    res.json({
      ok: true,
      service: 'gaslink-firebase-bridge',
      timestamp: new Date().toISOString(),
    });
  });

  async function handleSubscriber(req, res) {
    try {
      const phone = normalizePhone(req.query.phone || req.body?.phone);
      if (!isValidTzPhone(phone)) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'A valid Tanzanian phone is required',
        });
      }
      const subscriber = await findSubscriber(phone);
      return res.json(subscriberResponse(subscriber));
    } catch (error) {
      return res.status(500).json({ error: 'Bridge error', message: error.message });
    }
  }

  router.get('/subscriber', handleSubscriber);
  router.post('/subscriber', handleSubscriber);

  router.get('/catalog', async (req, res) => {
    try {
      const firestore = db();
      const [productsSnap, vendors] = await Promise.all([
        firestore.collection('products').limit(1000).get(),
        vendorMap(),
      ]);

      const products = [];
      productsSnap.docs.forEach((doc) => {
        const data = doc.data() || {};
        const vendor = vendors.get(
          (data.vendor_id || data.vendorId || '').toString(),
        );
        if (!vendor) return;
        const inStock = data.in_stock !== false && data.inStock !== false;
        const brand = (data.brand || 'Gesi').toString();
        const mapped = brandColor(brand);
        products.push({
          id: doc.id,
          vendorId: vendor.id,
          vendorName: vendor.name,
          vendorArea: vendor.area,
          vendorVerified: vendor.verified,
          brand,
          color: mapped.color,
          colorAliases: mapped.aliases,
          size: (data.size || data.weight || '').toString(),
          price: Number(data.price || 0),
          inStock,
          category: (data.category || 'refill').toString(),
        });
      });

      const groups = new Map();
      for (const product of products) {
        const key = `${product.brand}__${product.size}`;
        if (!groups.has(key)) {
          const mapped = brandColor(product.brand);
          groups.set(key, {
            brand: product.brand,
            size: product.size,
            color: mapped.color,
            colorAliases: mapped.aliases,
            refillPrice: null,
            fullSetPrice: null,
            inStock: false,
            offers: [],
          });
        }
        const group = groups.get(key);
        if (product.inStock) group.inStock = true;
        if (product.category === 'refill') {
          group.refillPrice =
            group.refillPrice === null
              ? product.price
              : Math.min(group.refillPrice, product.price);
        }
        if (product.category === 'full_set') {
          group.fullSetPrice =
            group.fullSetPrice === null
              ? product.price
              : Math.min(group.fullSetPrice, product.price);
        }
        group.offers.push({
          vendorId: product.vendorId,
          vendorName: product.vendorName,
          area: product.vendorArea,
          verified: product.vendorVerified,
          price: product.price,
          category: product.category,
          inStock: product.inStock,
        });
      }

      return res.json({
        ok: true,
        currency: 'TZS',
        deliveryArea: 'Dar es Salaam',
        generatedAt: new Date().toISOString(),
        brandColors: BRAND_COLORS.map((entry) => ({
          brand: entry.brand,
          color: entry.color,
          aliases: entry.aliases,
        })),
        products,
        groups: Array.from(groups.values()),
      });
    } catch (error) {
      return res.status(500).json({ error: 'Bridge error', message: error.message });
    }
  });

  router.post('/orders', async (req, res) => {
    try {
      const body = req.body || {};
      const phone = normalizePhone(body.phone);
      if (!isValidTzPhone(phone)) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'A valid Tanzanian phone is required',
        });
      }

      const subscriber = await findSubscriber(phone);
      if (!subscriber) {
        return res.status(404).json({
          error: 'Subscriber not found',
          message: 'No GasLink account uses this phone number',
        });
      }
      if (!subscriber.aiAssistantEnabled) {
        return res.status(403).json({
          error: 'AI assistant disabled',
          message: 'The customer has not opted into the AI SMS assistant',
        });
      }

      const vendorId = (body.vendorId || '').toString().trim();
      const brand = (body.brand || '').toString().trim();
      const size = (body.size || '').toString().trim();
      if (!vendorId || !brand || !size) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'vendorId, brand and size are required',
        });
      }

      const firestore = db();
      const vendorDoc = await firestore.collection('vendors').doc(vendorId).get();
      if (!vendorDoc.exists) {
        return res.status(404).json({
          error: 'Vendor not found',
          message: 'Unknown vendorId',
        });
      }
      const vendor = vendorDoc.data() || {};
      const vendorStatus = (vendor.status || '').toString().toLowerCase();
      if (vendor.active === false || vendorStatus === 'suspended' || vendorStatus === 'rejected') {
        return res.status(409).json({
          error: 'Vendor unavailable',
          message: 'This vendor is not accepting orders',
        });
      }

      const category = (body.category || 'refill').toString().toLowerCase();
      const product = await findProduct(vendorId, brand, size, category);
      if (!product) {
        return res.status(404).json({
          error: 'Product not found',
          message: 'No matching product for this vendor, brand and size',
        });
      }
      const productData = product.data;
      const inStock = productData.in_stock !== false && productData.inStock !== false;
      if (!inStock) {
        return res.status(409).json({
          error: 'Out of stock',
          message: 'The requested product is out of stock',
        });
      }

      const rawQuantity = Number(body.quantity || 1);
      const quantity =
        Number.isFinite(rawQuantity) && rawQuantity > 0
          ? Math.floor(rawQuantity)
          : 1;
      const unitPrice = Number(productData.price || 0);
      if (!Number.isFinite(unitPrice) || unitPrice <= 0) {
        return res.status(409).json({
          error: 'Invalid price',
          message: 'The product has no valid live price',
        });
      }

      const isSubscription =
        (vendor.commissionModel || vendor.commission_model || '') === 'subscription';
      const commissionRate = isSubscription
        ? 0
        : Number(vendor.commissionRate ?? vendor.commission_rate ?? 0.03);
      const total = unitPrice * quantity;
      const address = (
        body.address ||
        vendor.areaText ||
        vendor.district ||
        'Dar es Salaam'
      ).toString();

      const orderIntent = ['new_asset', 'add_stock', 'swap'].includes(
        body.orderIntent,
      )
        ? body.orderIntent
        : 'new_asset';

      const order = {
        consumer_uid: subscriber.uid,
        consumerUid: subscriber.uid,
        vendor_id: vendorId,
        vendorId,
        vendor_name: (vendor.businessName || vendor.business_name || 'Muuzaji Gesi').toString(),
        vendorName: (vendor.businessName || vendor.business_name || 'Muuzaji Gesi').toString(),
        product_id: product.id,
        brand_name: brand,
        brand,
        brandName: brand,
        cylinder_weight: size,
        weight: size,
        size,
        type: category,
        order_intent: orderIntent,
        orderIntent,
        quantity,
        unit_price: unitPrice,
        unitPrice,
        total_price: total,
        totalPrice: total,
        total,
        commission_rate: commissionRate,
        commission_due: total * commissionRate,
        commission_model: isSubscription ? 'subscription' : 'percentage',
        billed: false,
        status: 'placed',
        delivery_address: address,
        deliveryAddress: address,
        contact_phone: phone,
        consumerPhone: phone,
        receiver_phone: phone,
        special_requests: (body.notes || '').toString(),
        payment_method: (body.paymentMethod || 'cash').toString(),
        latitude: vendor.latitude || null,
        longitude: vendor.longitude || null,
        vendorViewed: false,
        vendor_viewed: false,
        source: 'sms_ai',
        ai_session_id: (body.sessionId || '').toString(),
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      let orderRef;
      if (body.idempotencyKey) {
        const digest = crypto
          .createHash('sha256')
          .update(String(body.idempotencyKey))
          .digest('hex')
          .slice(0, 24);
        orderRef = firestore.collection('orders').doc(`sms_${digest}`);
        try {
          await orderRef.create(order);
        } catch (error) {
          if (error.code === 6 || error.code === 'already-exists') {
            const existing = await orderRef.get();
            return res.status(200).json({
              ok: true,
              duplicate: true,
              orderId: existing.id,
              status: (existing.data() || {}).status || 'placed',
            });
          }
          throw error;
        }
      } else {
        orderRef = await firestore.collection('orders').add(order);
      }

      // Best-effort vendor ledger entry, matching the Flutter notification flow.
      try {
        const vendorUserDoc = await firestore
          .collection('users')
          .doc(vendorId)
          .get();
        const vendorUser = vendorUserDoc.data() || {};
        const channel = (vendorUser.notification_channel || 'both').toString();
        const wantsPush = channel === 'push_only' || channel === 'both';
        const fcmToken = (
          vendor.fcmToken ||
          vendorUser.fcmToken ||
          vendorUser.fcm_token ||
          ''
        ).toString();
        if (wantsPush && fcmToken) {
          await firestore.collection('notifications').add({
            userId: vendorId,
            fcmToken,
            title: 'Oda Mpya!',
            body: `Umepokea oda mpya ya ${brand} (${size}).`,
            data: { orderId: orderRef.id, type: 'new_order' },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false,
          });
        }
      } catch (notifyError) {
        console.warn('[bridge] vendor notification warning:', notifyError.message);
      }

      return res.status(201).json({
        ok: true,
        orderId: orderRef.id,
        status: 'placed',
        total,
        currency: 'TZS',
      });
    } catch (error) {
      return res.status(500).json({ error: 'Bridge error', message: error.message });
    }
  });

  return router;
}

module.exports = {
  createFirebaseBridgeRouter,
  normalizePhone,
  isValidTzPhone,
  brandColor,
  subscriberResponse,
};
