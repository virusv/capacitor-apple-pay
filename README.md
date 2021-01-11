# Capacitor плагин для реализации функции оплаты через Apple Pay

Плагин находится на стадии разработки!

The plugin is under development!

## Install
```bash
npm i capacitor-apple-pay@git://github.com/virusv/capacitor-apple-pay.git

npx cap sync ios
```

## Can make payments
```ts
const { isPayment } = await ApplePay.canMakePayments();

if (isPayment) {
    // ... Request payment
}
```

## Make payment request

See docs: https://developer.apple.com/documentation/passkit/pkpaymentrequest

```ts
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
    countryCode: 'US';
    currencyCode: 'USD';
    // supportedCountries: [ ... ];
    supportedNetworks: [ 'mastercard', 'visa', 'amex', 'quicPay', 'chinaUnionPay', 'discover', 'interac', 'privateLabel' ];
    requiredShippingContactFields: [ 'emailAddress', 'name', 'phoneNumber', 'phoneticName', 'postalAddress' ];
    requiredBillingContactFields: [ 'emailAddress', 'name', 'phoneNumber', 'phoneticName', 'postalAddress' ];
    merchantCapabilities: [ 'capability3DS', 'capabilityCredit', 'capabilityDebit', 'capabilityEMV' ];
    
    // billingContact?: PaymentContact;
    // shippingContact?: PaymentContact;
};

// See: https://developer.apple.com/documentation/passkit/pkpaymenttoken
const { token } = await ApplePay.makePaymentRequest(paymentRequest);

try {
    await MyPaymentProvider.authorize(token.paymentData);
    ApplePay.completeLastTransaction({ status: 'success' });
} catch {
    ApplePay.completeLastTransaction({ status: 'error' });
}
```