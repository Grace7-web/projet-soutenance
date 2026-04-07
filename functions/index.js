const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const MOMO_SUBS_KEY =
  process.env.MOMO_COLLECTION_SUB_KEY ||
  (functions.config().momo && functions.config().momo.collection_key) ||
  '';
const MOMO_USER_ID =
  process.env.MOMO_USER_ID ||
  (functions.config().momo && functions.config().momo.user_id) ||
  '';
const MOMO_API_KEY =
  process.env.MOMO_API_KEY ||
  (functions.config().momo && functions.config().momo.api_key) ||
  '';
const MOMO_ENV =
  process.env.MOMO_TARGET_ENV ||
  (functions.config().momo && functions.config().momo.target_env) ||
  'sandbox';

const momoBase = MOMO_ENV === 'production'
  ? 'https://proxy.momoapi.mtn.com'
  : 'https://sandbox.momodeveloper.mtn.com';

async function momoAccessToken() {
  if (!MOMO_USER_ID || !MOMO_API_KEY || !MOMO_SUBS_KEY) {
    throw new Error('MOMO credentials missing');
  }
  const cred = Buffer.from(`${MOMO_USER_ID}:${MOMO_API_KEY}`).toString('base64');
  const res = await fetch(`${momoBase}/collection/token/`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${cred}`,
      'Ocp-Apim-Subscription-Key': MOMO_SUBS_KEY,
    },
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`MOMO token error ${res.status}: ${txt}`);
  }
  const data = await res.json();
  return data.access_token;
}

function uuidV4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

exports.momoCollect = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  try {
    const { phone, amount, currency, reference } = req.body || {};
    if (!phone || !amount || !currency || !reference) {
      res.status(400).json({ error: 'Missing fields' });
      return;
    }
    const token = await momoAccessToken();
    const refId = uuidV4();
    const body = {
      amount: String(amount),
      currency,
      externalId: reference,
      payer: { partyIdType: 'MSISDN', partyId: String(phone) },
      payerMessage: 'marketmboa',
      payeeNote: 'marketmboa',
    };
    const createRes = await fetch(
      `${momoBase}/collection/v1_0/requesttopay`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'X-Target-Environment': MOMO_ENV,
          'X-Reference-Id': refId,
          'Ocp-Apim-Subscription-Key': MOMO_SUBS_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      }
    );
    if (createRes.status !== 202) {
      const t = await createRes.text();
      res.status(createRes.status).send(t);
      return;
    }
    await admin.firestore().collection('payments').doc(reference).set({
      provider: 'mtn_momo',
      momoRefId: refId,
      phone: String(phone),
      amount: Number(amount),
      currency,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    res.json({ referenceId: refId, message: 'Paiement initié' });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

exports.paymentStatus = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'GET') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  try {
    const reference = (req.path.split('/').pop() || '').trim() || req.query.ref;
    if (!reference) {
      res.status(400).json({ error: 'Missing reference' });
      return;
    }
    const snap = await admin.firestore().collection('payments').doc(reference).get();
    if (!snap.exists) {
      res.status(404).json({ error: 'Payment not found' });
      return;
    }
    const data = snap.data();
    if (data.provider === 'mtn_momo') {
      const token = await momoAccessToken();
      const sRes = await fetch(
        `${momoBase}/collection/v1_0/requesttopay/${data.momoRefId}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'X-Target-Environment': MOMO_ENV,
            'Ocp-Apim-Subscription-Key': MOMO_SUBS_KEY,
          },
        }
      );
      if (!sRes.ok) {
        const txt = await sRes.text();
        res.status(sRes.status).send(txt);
        return;
      }
      const sData = await sRes.json();
      const status = (sData.status || '').toLowerCase();
      await snap.ref.set({ status, providerResp: sData }, { merge: true });
      res.json({ status, details: sData });
      return;
    }
    res.status(501).json({ error: 'Provider not supported' });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

exports.orangeCollect = functions.https.onRequest(async (req, res) => {
  res.status(501).json({ error: 'Orange Money non configuré' });
});

// =========================
// CinetPay (agrégateur)
// =========================
const CINETPAY_API_KEY =
  process.env.CINETPAY_API_KEY ||
  (functions.config().cinetpay && functions.config().cinetpay.api_key) ||
  '';
const CINETPAY_SITE_ID =
  process.env.CINETPAY_SITE_ID ||
  (functions.config().cinetpay && functions.config().cinetpay.site_id) ||
  '';
const CINETPAY_BASE =
  process.env.CINETPAY_BASE ||
  (functions.config().cinetpay && functions.config().cinetpay.base_url) ||
  'https://api-checkout.cinetpay.com';
const CINETPAY_NOTIFY_URL =
  process.env.CINETPAY_NOTIFY_URL ||
  (functions.config().cinetpay && functions.config().cinetpay.notify_url) ||
  '';

exports.cinetpayInit = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  try {
    const { phone, amount, currency, reference, description, channel } =
      req.body || {};
    if (!phone || !amount || !currency || !reference) {
      res.status(400).json({ error: 'Missing fields' });
      return;
    }
    if (!CINETPAY_API_KEY || !CINETPAY_SITE_ID) {
      res.status(500).json({ error: 'CinetPay config missing' });
      return;
    }
    const payload = {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: reference,
      amount: Number(amount),
      currency: currency || 'XAF',
      description: description || 'marketmboa',
      notify_url: CINETPAY_NOTIFY_URL || '',
      return_url: CINETPAY_NOTIFY_URL || '',
      channels: 'MOBILE_MONEY',
      customer_phone_number: String(phone),
      // Optionally hint operator
      metadata: { channel: channel || '' },
    };
    const initRes = await fetch(`${CINETPAY_BASE}/v2/payment`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const initBody = await initRes.text();
    let initData;
    try {
      initData = JSON.parse(initBody);
    } catch (_) {
      initData = { message: initBody };
    }
    if (!initRes.ok || !initData || !initData.data) {
      res.status(initRes.status).json({ error: initData || initBody });
      return;
    }
    const paymentUrl =
      initData.data.payment_url || initData.data.checkout_url || '';
    await admin
      .firestore()
      .collection('payments')
      .doc(reference)
      .set(
        {
          provider: 'cinetpay',
          phone: String(phone),
          amount: Number(amount),
          currency,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    res.json({ paymentUrl, message: 'Paiement CinetPay initié' });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

exports.cinetpayStatus = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'GET') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  try {
    const reference =
      (req.path.split('/').pop() || '').trim() || req.query.ref || '';
    if (!reference) {
      res.status(400).json({ error: 'Missing reference' });
      return;
    }
    if (!CINETPAY_API_KEY || !CINETPAY_SITE_ID) {
      res.status(500).json({ error: 'CinetPay config missing' });
      return;
    }
    const payload = {
      apikey: CINETPAY_API_KEY,
      site_id: CINETPAY_SITE_ID,
      transaction_id: reference,
    };
    const sRes = await fetch(`${CINETPAY_BASE}/v2/payment/check`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const body = await sRes.json().catch(async () => ({
      error: await sRes.text(),
    }));
    if (!sRes.ok) {
      res.status(sRes.status).json(body);
      return;
    }
    const cpStatus = (body.data && body.data.status) || '';
    const status = cpStatus.toLowerCase();
    await admin
      .firestore()
      .collection('payments')
      .doc(reference)
      .set({ status, providerResp: body }, { merge: true });
    res.json({ status, details: body });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

/**
 * Envoi de notification push lors d'un nouveau message
 */
exports.onNewMessage = functions.firestore
  .document('conversations/{convId}/messages/{msgId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const receiverId = message.receiverId;

    if (!receiverId) return null;

    // Récupérer le token FCM du destinataire
    const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
    const userData = userDoc.data();

    if (!userData || !userData.fcmToken) {
      console.log('Aucun token FCM pour l\'utilisateur:', receiverId);
      return null;
    }

    const payload = {
      notification: {
        title: 'Nouveau message de MarketMboa',
        body: message.text || 'Vous avez reçu un message',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
      data: {
        conversationId: context.params.convId,
        type: 'chat'
      }
    };

    try {
      await admin.messaging().sendToDevice(userData.fcmToken, payload);
      console.log('Notification envoyée avec succès');
    } catch (error) {
      console.error('Erreur envoi notification:', error);
    }
  });

exports.cinetpayNotify = functions.https.onRequest(async (req, res) => {
  try {
    const { transaction_id, status } = req.body || {};
    if (!transaction_id) {
      res.status(400).send('Missing transaction_id');
      return;
    }
    await admin
      .firestore()
      .collection('payments')
      .doc(transaction_id)
      .set({ status: (status || 'unknown').toLowerCase() }, { merge: true });
    res.status(200).send('OK');
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

// =========================
// NotchPay (agrégateur recommandé)
// =========================
const NOTCHPAY_PUBLIC_KEY =
  process.env.NOTCHPAY_PUBLIC_KEY ||
  (functions.config().notchpay && functions.config().notchpay.public_key) ||
  'pk_test.scDIlmLZpBHVNDmoRfq5oq5bpa89f7XWuOnHnqhTjtGD0XEazNSNoLFo2BGNnwj86k8dG9RxwW96B3blRIDTTww4eRQIGT5YJi3hr0l9o6L9MpBYlyMOJAuu9rC4Z';
const NOTCHPAY_SECRET_KEY =
  process.env.NOTCHPAY_SECRET_KEY ||
  (functions.config().notchpay && functions.config().notchpay.secret_key) ||
  'sk_test.a2U5ChNU6oSJsc0vj2D5HR4LAeXoWQAivkWhmMTkPS3PIYTPOvPUmY7uJ79zVvMiO8mJYeiDZCDsXSRh4cPdcVPuUGlhdMzN1w95yWuQq9st1OOJ2IXHZ3akEjkp6';
const NOTCHPAY_BASE = 'https://api.notchpay.co';

exports.notchpayInit = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  try {
    const { amount, currency, email, name, phone, reference, description } = req.body || {};
    if (!amount || !currency || !email || !reference) {
      res.status(400).json({ error: 'Missing fields (amount, currency, email, reference are required)' });
      return;
    }

    const payload = {
      amount: Number(amount),
      currency: currency || 'XAF',
      email: email,
      name: name || 'Client MarketMboa',
      phone: phone || '',
      reference: reference,
      description: description || 'Paiement MarketMboa',
      callback: `https://marketmboa.web.app/payment-callback?ref=${reference}`, // URL de retour après paiement
    };

    const initRes = await fetch(`${NOTCHPAY_BASE}/payments/initialize`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': NOTCHPAY_PUBLIC_KEY, // NotchPay utilise la clé publique pour l'init
        'Accept': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const initData = await initRes.json();

    if (!initRes.ok) {
      res.status(initRes.status).json(initData);
      return;
    }

    // Sauvegarder dans Firestore
    await admin.firestore().collection('payments').doc(reference).set({
      provider: 'notchpay',
      amount: Number(amount),
      currency: currency,
      email: email,
      status: 'pending',
      notchpayRef: initData.transaction?.reference || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    res.json({
      paymentUrl: initData.authorization_url,
      reference: reference,
      message: 'Paiement NotchPay initié'
    });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

exports.notchpayStatus = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'GET') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  try {
    const reference = req.query.ref || req.path.split('/').pop();
    if (!reference) {
      res.status(400).json({ error: 'Missing reference' });
      return;
    }

    // NotchPay demande la clé secrète pour vérifier le statut
    const sRes = await fetch(`${NOTCHPAY_BASE}/payments/${reference}`, {
      method: 'GET',
      headers: {
        'Authorization': NOTCHPAY_SECRET_KEY,
        'Accept': 'application/json',
      },
    });

    const sData = await sRes.json();
    if (!sRes.ok) {
      res.status(sRes.status).json(sData);
      return;
    }

    const status = (sData.payment?.status || 'pending').toLowerCase();
    
    // Mettre à jour Firestore
    await admin.firestore().collection('payments').doc(reference).set({
      status: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      providerResp: sData
    }, { merge: true });

    res.json({ status, details: sData });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

exports.notchpayWebhook = functions.https.onRequest(async (req, res) => {
  // TODO: Vérifier la signature X-Notch-Signature pour la sécurité
  try {
    const event = req.body;
    const reference = event.data?.reference;
    const status = event.data?.status;

    if (reference && status) {
      await admin.firestore().collection('payments').doc(reference).set({
        status: status.toLowerCase(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        webhookData: event
      }, { merge: true });
    }
    res.status(200).send('OK');
  } catch (e) {
    res.status(500).send(String(e));
  }
});
