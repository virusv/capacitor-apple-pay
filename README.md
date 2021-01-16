# Capacitor plugin to implement payment function via Apple Pay

Плагин находится на стадии разработки!

The plugin is under development!

demo application: [GitHub](https://github.com/virusv/capacitor-apple-pay-demo-app)

## Install
```bash
npm i capacitor-apple-pay

npx cap sync ios
```

## Import TS definition for VSCode
for some reason type definitions don't work:
`declare module '@capacito/core' { interface PluginRegistry { ...`

```ts
import { ApplePayPlugin } from 'capacitor-apple-pay'
import { Plugins } from '@capacitor/core'
const ApplePay = Plugins.ApplePay as ApplePayPlugin;
```

## Can make payments
```js
const { isPayment } = await ApplePay.canMakePayments();

// OR

const { isPayment } = await ApplePay.canMakePayments({
  usingNetworks: [ ... ];
  capabilities: [ ... ];
});

if (isPayment) {
    // ... Request payment
}
```

## Make payment request

See docs: https://developer.apple.com/documentation/passkit/pkpaymentrequest

```js
const paymentRequest = {
    // Requiered
    merchantIdentifier: "com.apple.testing",
    paymentSummaryItems: [
      {
        label: 'order #1001',
        amount: 120.57,
        // type: 'pending' // or default: final
      },
      // ...
    ],

    // Outher
    countryCode: 'US',
    currencyCode: 'USD',

    supportedNetworks: [
      'mastercard', 'visa', 'amex',
      'quicPay', 'chinaUnionPay', 'discover',
      'interac', 'privateLabel'
    ],

    merchantCapabilities: [
      'capability3DS', 'capabilityCredit',
      'capabilityDebit', 'capabilityEMV'
    ],

    requiredShippingContactFields: [
      'emailAddress', 'name', 'phoneNumber',
      'phoneticName', 'postalAddress'
    ],

    requiredBillingContactFields: [
      'emailAddress', 'name', 'phoneNumber',
      'phoneticName', 'postalAddress'
    ],
    
    // supportedCountries: [ ... ],
    // billingContact: PaymentContact,
    // shippingContact: PaymentContact,
};

try {
  // See: https://developer.apple.com/documentation/passkit/pkpaymenttoken
  const { token } = await ApplePay.makePaymentRequest(paymentRequest);

  try {
    // INFO: Check and completion of the payment by your processing center
    await MyPaymentProvider.authorize(token.paymentData);

    ApplePay.completeLastTransaction({ status: 'success' });
  } catch {
    ApplePay.completeLastTransaction({ status: 'error' });
  }
} catch (e) {
  if (e.message === 'canceled') {
    // Payment widget was closed by user
  }
}
```