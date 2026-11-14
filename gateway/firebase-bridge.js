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
  { brand: 'Manjis Gas', match: /manjis/i, color: 'Grey', aliases: ['grey', 'gray', 'kijivu'] },
  { brand: 'Mihan Gas', match: /mihan/i, color: 'Yellow', aliases: ['yellow', 'njano'] },
  { brand: 'O-Gas', match: /^o[\s-]?gas$/i, color: 'Yellow', aliases: ['yellow', 'njano'] },
  { brand: 'Taifa Gas', match: /taifa/i, color: 'Green', aliases: ['green', 'kijani'] },
  { brand: 'O-Lake / Lake Gas', match: /lake/i, color: 'Blue', aliases: ['blue', 'bluu'] },
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
      area: (data.area || data.ward || '').toString(),
      address: (data.address || data.deliveryAddress || '').toString(),
      ward: (data.ward || '').toString(),
      district: (data.district || '').toString(),
      profileCompleted: data.profileCompleted === true,
      preferredBrand: (data.preferredBrand || '').toString(),
      preferredSize: (data.preferredSize || '').toString(),
    };
  }

  async function buildSubscriberProfile(subscriber) {
    if (!subscriber) return null;
    const firestore = db();
    let cylinders = [];
    try {
      const snap = await firestore
        .collection('users')
        .doc(subscriber.uid)
        .collection('cylinders')
        .limit(10)
        .get();
      cylinders = snap.docs.map((doc) => {
        const d = doc.data() || {};
        return {
          brand: (d.brand || '').toString(),
          size: (d.size || d.weight || d.cylinder_weight || '').toString(),
          lastRefillDate: (d.lastRefillDate || d.purchase_date || '').toString(),
          refillCycle: (d.refillCycle || '30 days').toString(),
        };
      });
    } catch (error) {
      console.warn('[bridge] cylinder profile warning:', error.message);
    }
    return {
      name: subscriber.name || '',
      area: subscriber.area || '',
      address: subscriber.address || '',
      ward: subscriber.ward || '',
      district: subscriber.district || '',
      profileCompleted: subscriber.profileCompleted,
      preferredBrand: subscriber.preferredBrand || '',
      preferredSize: subscriber.preferredSize || '',
      cylinders,
    };
  }

  async function findVendorByPhone(phone) {
    const firestore = db();
    const variants = phoneVariants(phone);
    const [primary, secondary] = await Promise.all([
      firestore.collection('vendors').where('phone', 'in', variants).limit(1).get(),
      firestore
        .collection('vendors')
        .where('secondaryPhone', 'in', variants)
        .limit(1)
        .get()
        .catch(() => ({ empty: true, docs: [] })),
    ]);
    const doc =
      (!primary.empty && primary.docs[0]) ||
      (!secondary.empty && secondary.docs[0]);
    if (!doc) return null;
    const data = doc.data() || {};
    return {
      id: doc.id,
      name: (data.businessName || data.business_name || data.shop_name || 'Muuzaji Gesi').toString(),
      phone: (data.phone || '').toString(),
      secondaryPhone: (data.secondaryPhone || '').toString(),
      area: (data.areaText || data.ward || data.district || '').toString(),
    };
  }

  function orderCode(orderId) {
    return String(orderId || '').replace(/[^a-zA-Z0-9]/g, '').slice(-6).toUpperCase();
  }

  async function vendorContact(vendorId) {
    const doc = await db().collection('vendors').doc(vendorId).get();
    if (!doc.exists) return null;
    const data = doc.data() || {};
    return {
      id: doc.id,
      name: (data.businessName || data.business_name || data.shop_name || 'Muuzaji Gesi').toString(),
      phone: (data.phone || '').toString(),
      secondaryPhone: (data.secondaryPhone || '').toString(),
    };
  }

  async function notifyUser(userId, title, body, data = {}) {
    if (!userId) return;
    const firestore = db();
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;
    const user = userDoc.data() || {};
    const channel = (user.notification_channel || 'both').toString();
    const wantsPush = channel === 'push_only' || channel === 'both';
    const fcmToken = (user.fcmToken || user.fcm_token || '').toString();
    if (wantsPush && fcmToken) {
      await firestore.collection('notifications').add({
        userId,
        fcmToken,
        title,
        body,
        data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });
    }
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
        deliveryType: (data.deliveryType || data.delivery_type || '').toString(),
        deliveryFee: data.deliveryFee ?? data.delivery_fee ?? null,
        deliveryFeeModel: (data.deliveryFeeModel || data.delivery_fee_model || '').toString(),
        deliveryRadiusKm: Number(data.deliveryRadiusKm ?? data.delivery_radius_km ?? 0),
        openingHours: (data.openingHours || data.opening_hours || '').toString(),
        hasOperationalScale: data.hasOperationalScale === true || data.has_operational_scale === true,
        hasCertifiedScale: data.hasCertifiedScale === true || data.has_certified_scale === true,
        acceptsCash: data.acceptsCash !== false,
        acceptsMobileMoney: data.acceptsMobileMoney === true,
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
      const response = subscriberResponse(subscriber);
      if (subscriber && subscriber.aiAssistantEnabled) {
        response.profile = await buildSubscriberProfile(subscriber);
      }
      return res.json(response);
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
        vendors: Array.from(vendors.values()),
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

  function orderTime(data) {
    const value = data.created_at || data.createdAt || data.createdAtMs;
    if (!value) return 0;
    if (typeof value.toMillis === 'function') return value.toMillis();
    if (value instanceof Date) return value.getTime();
    const parsed = Date.parse(String(value));
    return Number.isFinite(parsed) ? parsed : 0;
  }

  router.get('/orders/status', async (req, res) => {
    try {
      const phone = normalizePhone(req.query.phone);
      if (!isValidTzPhone(phone)) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'A valid Tanzanian phone is required',
        });
      }
      const subscriber = await findSubscriber(phone);
      if (!subscriber) return res.json({ ok: true, orders: [] });

      const firestore = db();
      const limit = Math.min(5, Math.max(1, Number(req.query.limit) || 2));
      let docs = [];
      try {
        const snap = await firestore
          .collection('orders')
          .where('consumer_uid', '==', subscriber.uid)
          .limit(20)
          .get();
        docs = snap.docs;
      } catch (error) {
        console.warn('[bridge] order status uid query:', error.message);
      }
      if (!docs.length) {
        try {
          const snap = await firestore
            .collection('orders')
            .where('contact_phone', 'in', phoneVariants(phone))
            .limit(20)
            .get();
          docs = snap.docs;
        } catch (error) {
          console.warn('[bridge] order status phone query:', error.message);
        }
      }

      const sorted = docs
        .sort((a, b) => orderTime(b.data() || {}) - orderTime(a.data() || {}))
        .slice(0, limit);

      const orders = [];
      for (const doc of sorted) {
        const order = doc.data() || {};
        const status = (order.status || 'placed').toString();
        const confirmed = ['confirmed', 'on_the_way', 'delivered_pending', 'delivered'].includes(status);
        const dispatched = ['on_the_way', 'delivered_pending', 'delivered'].includes(status);
        let vendorPhone = '';
        if (confirmed) {
          const contact = await vendorContact(
            (order.vendor_id || order.vendorId || '').toString(),
          );
          vendorPhone = contact ? (contact.phone || contact.secondaryPhone || '') : '';
        }
        const driverPhone = dispatched
          ? (order.driver_phone || order.driverPhone || '').toString()
          : '';
        orders.push({
          id: doc.id,
          code: orderCode(doc.id),
          status,
          brand: (order.brand || order.brand_name || order.brandName || '').toString(),
          size: (order.size || order.weight || order.cylinder_weight || '').toString(),
          quantity: Number(order.quantity || 1),
          total: Number(order.total ?? order.total_price ?? order.totalPrice ?? 0),
          currency: 'TZS',
          vendorId: (order.vendor_id || order.vendorId || '').toString(),
          vendorName: (order.vendor_name || order.vendorName || '').toString(),
          etaMinutes: Number(order.eta_minutes || order.etaMinutes || 0) || null,
          vendorPhone,
          driverPhone,
          createdAt: order.created_at || order.createdAt || null,
        });
      }
      return res.json({ ok: true, orders });
    } catch (error) {
      return res.status(500).json({ error: 'Bridge error', message: error.message });
    }
  });

  router.get('/vendors/contact', async (req, res) => {
    try {
      const vendorId = (req.query.vendorId || '').toString().trim();
      if (!vendorId) {
        return res.status(400).json({ error: 'Bad Request', message: 'vendorId is required' });
      }
      const contact = await vendorContact(vendorId);
      if (!contact) {
        return res.status(404).json({ error: 'Vendor not found' });
      }
      return res.json({ ok: true, vendor: contact });
    } catch (error) {
      return res.status(500).json({ error: 'Bridge error', message: error.message });
    }
  });

  router.get('/vendors/pending-order', async (req, res) => {
    try {
      const phone = normalizePhone(req.query.phone);
      if (!isValidTzPhone(phone)) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'A valid Tanzanian phone is required',
        });
      }
      const vendor = await findVendorByPhone(phone);
      if (!vendor) {
        return res.status(404).json({ error: 'Vendor not found' });
      }
      const snap = await db()
        .collection('orders')
        .where('status', 'in', ['placed', 'seen'])
        .limit(50)
        .get();
      const pending = snap.docs
        .map((doc) => ({ id: doc.id, data: doc.data() || {} }))
        .filter(
          ({ data }) =>
            (data.vendor_id || data.vendorId || '').toString() === vendor.id,
        )
        .sort((a, b) => orderTime(b.data) - orderTime(a.data));
      const latest = pending[0] || null;
      return res.json({
        ok: true,
        vendor,
        order: latest
          ? {
              id: latest.id,
              code: orderCode(latest.id),
              status: (latest.data.status || 'placed').toString(),
              brand: (latest.data.brand || latest.data.brand_name || '').toString(),
              size: (latest.data.size || latest.data.weight || '').toString(),
              quantity: Number(latest.data.quantity || 1),
              total: Number(latest.data.total ?? latest.data.total_price ?? 0),
              address: (latest.data.delivery_address || latest.data.deliveryAddress || '').toString(),
              createdAt: latest.data.created_at || latest.data.createdAt || null,
            }
          : null,
      });
    } catch (error) {
      return res.status(500).json({ error: 'Bridge error', message: error.message });
    }
  });

  router.post('/orders/vendor-response', async (req, res) => {
    try {
      const body = req.body || {};
      const phone = normalizePhone(body.phone);
      if (!isValidTzPhone(phone)) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'A valid Tanzanian phone is required',
        });
      }
      const vendor = await findVendorByPhone(phone);
      if (!vendor) {
        return res.status(403).json({ error: 'Not a vendor phone' });
      }
      const orderId = (body.orderId || '').toString().trim();
      const action = (body.response || '').toString().toLowerCase();
      if (!orderId || !['accept', 'reject'].includes(action)) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'orderId and response (accept|reject) are required',
        });
      }

      const firestore = db();
      const orderRef = firestore.collection('orders').doc(orderId);
      const orderDoc = await orderRef.get();
      if (!orderDoc.exists) {
        return res.status(404).json({ error: 'Order not found' });
      }
      const order = orderDoc.data() || {};
      const orderVendorId = (order.vendor_id || order.vendorId || '').toString();
      if (orderVendorId !== vendor.id) {
        return res.status(403).json({ error: 'Order does not belong to this vendor' });
      }
      const status = (order.status || 'placed').toString();
      if (['cancelled', 'delivered', 'delivered_pending'].includes(status)) {
        return res.status(409).json({ error: 'Order is already closed', status });
      }

      const consumerUid = (order.consumer_uid || order.consumerUid || '').toString();
      const customerPhone = (
        order.contact_phone ||
        order.consumerPhone ||
        order.receiver_phone ||
        ''
      ).toString();

      if (action === 'accept') {
        if (['planned', 'placed', 'seen'].includes(status)) {
          await orderRef.set(
            {
              status: 'confirmed',
              vendor_phone: vendor.phone || '',
              vendorPhone: vendor.phone || '',
              vendor_confirmed_at: admin.firestore.FieldValue.serverTimestamp(),
              updated_at: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          await notifyUser(
            consumerUid,
            'Oda imethibitishwa',
            `Oda yako ya ${order.brand || ''} imethibitishwa. Vendor: ${vendor.name}.`,
            { orderId, type: 'order_confirmed' },
          ).catch(() => {});
        } else if (!['confirmed', 'on_the_way'].includes(status)) {
          return res.status(409).json({ error: 'Order cannot be accepted', status });
        }
        return res.json({
          ok: true,
          status: 'confirmed',
          orderId,
          code: orderCode(orderId),
          customerPhone,
          vendorPhone: vendor.phone || vendor.secondaryPhone || '',
        });
      }

      if (!['placed', 'seen'].includes(status)) {
        return res.status(409).json({ error: 'Order cannot be rejected now', status });
      }
      await orderRef.set(
        {
          status: 'cancelled',
          cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
          cancellation_reason: 'vendor_rejected',
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      await notifyUser(
        consumerUid,
        'Oda imekataliwa',
        `Oda yako ya ${order.brand || ''} imekataliwa na vendor. Tutakusaidia kupata vendor mwingine.`,
        { orderId, type: 'order_rejected' },
      ).catch(() => {});
      return res.json({
        ok: true,
        status: 'cancelled',
        orderId,
        code: orderCode(orderId),
        vendorPhone: vendor.phone || vendor.secondaryPhone || '',
      });
    } catch (error) {
      return res.status(500).json({ error: 'Bridge error', message: error.message });
    }
  });

  router.post('/subscribers/sms', async (req, res) => {
    try {
      const body = req.body || {};
      const phone = normalizePhone(body.phone);
      if (!isValidTzPhone(phone)) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'A valid Tanzanian phone is required',
        });
      }
      const name = (body.name || '').toString().trim();
      const address = (body.address || '').toString().trim();
      if (!name || !address) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'name and address are required',
        });
      }

      const firestore = db();
      const existing = await findSubscriber(phone);
      let uid = existing ? existing.uid : '';
      let created = false;
      const profile = {
        phone,
        name,
        address,
        area: (body.area || '').toString().trim(),
        ward: (body.ward || '').toString().trim(),
        district: (body.district || '').toString().trim(),
        role: 'consumer',
        ai_assistant_enabled: true,
        notification_channel: 'both',
        sms_ordering_consent: true,
        profileCompleted: true,
        source: 'sms',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (uid) {
        await firestore.collection('users').doc(uid).set(profile, { merge: true });
      } else {
        const doc = await firestore.collection('users').add({
          ...profile,
          termsAcceptedAt: admin.firestore.FieldValue.serverTimestamp(),
          termsAcceptedVia: 'sms',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        uid = doc.id;
        created = true;
      }

      const cylinderBrand = (body.cylinderBrand || '').toString().trim();
      const cylinderSize = (body.cylinderSize || '').toString().trim();
      if (cylinderBrand && cylinderSize) {
        const cylindersRef = firestore.collection('users').doc(uid).collection('cylinders');
        const existingCylinders = await cylindersRef.limit(20).get();
        const duplicate = existingCylinders.docs.some((doc) => {
          const d = doc.data() || {};
          return (
            (d.brand || '').toString().toLowerCase() === cylinderBrand.toLowerCase() &&
            ((d.size || d.weight || '').toString().toLowerCase() === cylinderSize.toLowerCase())
          );
        });
        if (!duplicate) {
          const refillDate = body.lastRefillDate
            ? new Date(body.lastRefillDate)
            : new Date();
          const iso = Number.isNaN(refillDate.getTime())
            ? new Date().toISOString()
            : refillDate.toISOString();
          await cylindersRef.add({
            brand: cylinderBrand,
            size: cylinderSize,
            weight: cylinderSize,
            refillCycle: '30 days',
            lastRefillDate: iso,
            purchase_date: iso,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      return res.status(created ? 201 : 200).json({ ok: true, uid, created });
    } catch (error) {
      return res.status(500).json({ error: 'Bridge error', message: error.message });
    }
  });

  router.get('/safety', async (req, res) => {
    try {
      const snap = await db()
        .collection('safety_guidelines')
        .where('published', '==', true)
        .limit(10)
        .get()
        .catch(() => null);
      const items = snap
        ? snap.docs.map((doc) => {
            const d = doc.data() || {};
            return {
              id: doc.id,
              title: (d.title || '').toString(),
              titleSw: (d.titleSw || d.title_sw || '').toString(),
              body: (d.body || '').toString(),
              bodySw: (d.bodySw || d.body_sw || '').toString(),
              steps: Array.isArray(d.steps) ? d.steps : [],
              stepsSw: Array.isArray(d.stepsSw || d.steps_sw) ? (d.stepsSw || d.steps_sw) : [],
              order: Number(d.order || 0),
            };
          })
        : [];
      items.sort((a, b) => a.order - b.order);
      return res.json({ ok: true, items });
    } catch (error) {
      return res.status(500).json({ error: 'Bridge error', message: error.message });
    }
  });

  // Warm Firestore/gRPC at startup so the first subscriber check does not
  // hit the subscriber gate's short remote timeout after a cold start.
  try {
    db()
      .collection('users')
      .limit(1)
      .get()
      .catch((error) => {
        console.warn('[bridge] Firestore warm-up warning:', error.message);
      });
  } catch (error) {
    console.warn('[bridge] Firestore warm-up skipped:', error.message);
  }

  return router;
}

module.exports = {
  createFirebaseBridgeRouter,
  normalizePhone,
  isValidTzPhone,
  brandColor,
  subscriberResponse,
};
