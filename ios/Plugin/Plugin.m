#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(ApplePay, "ApplePay",
    CAP_PLUGIN_METHOD(completeLastTransaction, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(canMakePayments, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(makePaymentRequest, CAPPluginReturnPromise);
)
