import Foundation
import Capacitor
import PassKit

@objc(ApplePay)
public class ApplePay: CAPPlugin, PKPaymentAuthorizationControllerDelegate {
    var savedCall: CAPPluginCall?
    var lastCompletion: ((PKPaymentAuthorizationResult) -> Void)?
    var paymentPopupProcessing: Bool = false

    @objc func canMakePayments(_ call: CAPPluginCall) {
        var isPayment = false

        if !call.hasOption("usingNetworks") {
            isPayment = PKPaymentAuthorizationViewController.canMakePayments()
            call.success([ "isPayment": isPayment ])
            return
        }

        let networks = self.convertPaymentNetworks(
            call.getArray("usingNetworks", String.self) ?? [String]()
        )

        let rawCapabilities = call.getArray("capabilities", String.self) ?? [String]()

        if (rawCapabilities.count > 0) {
            let capabilities = self.convertMerchantCapabilitiesUnion(rawCapabilities)

            isPayment = PKPaymentAuthorizationViewController.canMakePayments(
                usingNetworks: networks,
                capabilities: capabilities
            )
        } else {
            isPayment = PKPaymentAuthorizationViewController.canMakePayments(
                usingNetworks: networks
            )
        }

        call.success([ "isPayment": isPayment ]);
    }

    @objc func makePaymentRequest(_ call: CAPPluginCall) {
        self.savedCall = call

        let paymentRequest = self.getPaymentRequest(call)
        let paymentAuth = PKPaymentAuthorizationController(paymentRequest: paymentRequest!)

        self.paymentPopupProcessing = true
        paymentAuth.delegate = self
        paymentAuth.present()
    }

    @objc func completeLastTransaction(_ call: CAPPluginCall) {
        let status = call.getString("status", "success");

        if self.lastCompletion == nil {
            call.reject("Did you make a payment request?")
            return;
        }

        switch status {
        case "success":
            self.lastCompletion?(PKPaymentAuthorizationResult(status: .success, errors: nil))
            break;
        default:
            // TODO:
            // var errors: [Error] = []
            // PKPaymentRequest.paymentShipping....

            self.lastCompletion?(PKPaymentAuthorizationResult(status: .failure, errors: nil))
        }

        self.lastCompletion = nil
        call.resolve()
    }

    func getPaymentRequest(_ call: CAPPluginCall) -> PKPaymentRequest? {
        let paymentRequest = PKPaymentRequest()

        paymentRequest.merchantIdentifier = call.getString("merchantIdentifier") ?? ""
        paymentRequest.countryCode = call.getString("countryCode") ?? "US"
        paymentRequest.currencyCode = call.getString("currencyCode") ?? "USD"
        paymentRequest.supportedCountries = Set<String>(call.getArray("supportedCountries", String.self) ?? [String]())

        paymentRequest.supportedNetworks = self.convertPaymentNetworks(
            call.getArray("supportedNetworks", String.self) ?? [String]()
        )
        paymentRequest.paymentSummaryItems = self.convertPaymentItems(
            call.getArray("paymentSummaryItems", NSDictionary.self) ?? [NSDictionary]()
        )
        paymentRequest.requiredShippingContactFields = self.convertContactFieldsList(
            call.getArray("requiredShippingContactFields", String.self) ?? [String]()
        )
        paymentRequest.requiredBillingContactFields = self.convertContactFieldsList(
            call.getArray("requiredBillingContactFields", String.self) ?? [String]()
        )
        paymentRequest.merchantCapabilities = self.convertMerchantCapabilitiesUnion(
            call.getArray("merchantCapabilities", String.self) ?? [String]()
        )

        if let billingContact = call.getObject("billingContact") {
            paymentRequest.billingContact = self.convertContact(billingContact as NSDictionary)
        }

        if let shippingContact = call.getObject("shippingContact") {
            paymentRequest.shippingContact = self.convertContact(shippingContact as NSDictionary)
        }

        return paymentRequest
    }

    func convertPaymentItems(_ items: [NSDictionary]) -> [PKPaymentSummaryItem] {
        var paymentItems: [PKPaymentSummaryItem] = []

        for dictionary in items {
            let label = dictionary["label"] as? String ?? "Empty label"
            let price = dictionary["amount"] as? Double ?? 0.0
            let type = self.convertPaymentItemType(dictionary["type"] as? String)

            paymentItems.append(
                PKPaymentSummaryItem(
                    label: label,
                    amount: NSDecimalNumber(floatLiteral: price),
                    type: type
                )
            )
        }

        return paymentItems
    }


    func convertPaymentNetworks(_ supportedNetworksRaw: [String]) -> [PKPaymentNetwork] {
        if supportedNetworksRaw.count == 0 {
            return [
                PKPaymentNetwork.masterCard,
                PKPaymentNetwork.visa,
                PKPaymentNetwork.amex,
                PKPaymentNetwork.quicPay,
                PKPaymentNetwork.chinaUnionPay,
                PKPaymentNetwork.discover,
                PKPaymentNetwork.interac,
                PKPaymentNetwork.privateLabel,
            ]
        }

        var supportedNetworks: [PKPaymentNetwork] = []
        for rawValue in supportedNetworksRaw {
            if let paymentType = convertPaymentSystem(rawValue) {
                supportedNetworks.append(paymentType)
            }
        }

        return supportedNetworks;
    }

    func convertContactFieldsList(_ fields: [String]) -> Set<PKContactField> {
        var contactFields: Set<PKContactField> = []

        for rawValue in fields {
            if let field = convertContactField(rawValue) {
                contactFields.insert(field)
            }
        }

        return contactFields
    }

    func convertMerchantCapabilitiesUnion(_ capabilities: [String]) -> PKMerchantCapability {
        if capabilities.count == 0 {
            return [
                PKMerchantCapability.capability3DS,
                PKMerchantCapability.capabilityDebit,
                PKMerchantCapability.capabilityCredit,
                PKMerchantCapability.capabilityEMV,
            ]
        }

        var merchantCapabilities = PKMerchantCapability()

        for rawValue in capabilities {
            if let capability = convertMerchantCapability(rawValue) {
                merchantCapabilities.insert(capability)
            }
        }

        return merchantCapabilities
    }

    func convertMerchantCapability(_ capability: String) -> PKMerchantCapability? {
        switch capability {
        case "capability3DS": return PKMerchantCapability.capability3DS
        case "capabilityCredit": return PKMerchantCapability.capabilityCredit
        case "capabilityDebit": return PKMerchantCapability.capabilityDebit
        case "capabilityEMV": return PKMerchantCapability.capabilityEMV
        default: return nil
        }
    }

    func convertContactField(_ field: String) -> PKContactField? {
        switch field {
        case "emailAddress": return PKContactField.emailAddress
        case "name": return PKContactField.name
        case "phoneNumber": return PKContactField.phoneNumber
        case "phoneticName": return PKContactField.phoneticName
        case "postalAddress": return PKContactField.postalAddress
        default: return nil
        }
    }

    func convertPersonNameComponents(_ name: NSDictionary) -> PersonNameComponents {
        var nameComponents = PersonNameComponents()

        nameComponents.familyName = name["familyName"] as? String
        nameComponents.givenName  = name["givenName"] as? String
        nameComponents.namePrefix = name["namePrefix"] as? String
        nameComponents.middleName = name["middleName"] as? String
        nameComponents.nameSuffix = name["nameSuffix"] as? String
        nameComponents.nickname   = name["nickname"] as? String

        if let phoneticRepresentation = name["phoneticRepresentation"] as? NSDictionary {
            nameComponents.phoneticRepresentation = self.convertPersonNameComponents(phoneticRepresentation)
        }

        return nameComponents;
    }

    func convertContact(_ information: NSDictionary) -> PKContact {
        let contact = PKContact()

        // DEPRECATED:
        // contact.supplementarySubLocality = information["supplementarySubLocality"] as? String

        contact.emailAddress = information["emailAddress"] as? String

        if let phone = information["phoneNumber"] as? String {
            contact.phoneNumber = CNPhoneNumber(stringValue: phone)
        }

        if let name = information["name"] as? NSDictionary {
            contact.name = self.convertPersonNameComponents(name)
        }

        if let postal = information["postalAddress"] as? NSDictionary {
            let postalAddress = CNMutablePostalAddress()

            postalAddress.street                = postal["street"] as? String ?? ""
            postalAddress.city                  = postal["city"] as? String ?? ""
            postalAddress.postalCode            = postal["postalCode"] as? String ?? ""
            postalAddress.country               = postal["country"] as? String ?? ""
            postalAddress.isoCountryCode        = postal["isoCountryCode"] as? String ?? ""
            postalAddress.subAdministrativeArea = postal["subAdministrativeArea"] as? String ?? ""
            postalAddress.subLocality           = postal["subLocality"] as? String ?? ""

            contact.postalAddress = postalAddress
        }

        return contact;
    }

    func convertPaymentItemType(_ item: String?) -> PKPaymentSummaryItemType {
        if (item == nil) { return PKPaymentSummaryItemType.final }

        switch item {
        case "pending": return PKPaymentSummaryItemType.pending
        case "final": return PKPaymentSummaryItemType.final
        default: return PKPaymentSummaryItemType.final
        }
    }

    func convertPaymentSystem(_ item: String) -> PKPaymentNetwork? {
        switch item {
        case "mastercard": return PKPaymentNetwork.masterCard
        case "visa": return PKPaymentNetwork.visa
        case "amex": return PKPaymentNetwork.amex
        case "quicPay": return PKPaymentNetwork.quicPay
        case "chinaUnionPay": return PKPaymentNetwork.chinaUnionPay
        case "discover": return PKPaymentNetwork.discover
        case "interac": return PKPaymentNetwork.interac
        case "privateLabel": return PKPaymentNetwork.privateLabel
        default: return nil
        }
    }

    // ----------------------------------------------------------------------------------------------
    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        // Если после открытия платежа метод paymentAuthorizationController
        // не вызывался, это означает, что пользователь закрыл окно оплаты
        if (self.paymentPopupProcessing) {
            self.savedCall?.reject("canceled")
            self.paymentPopupProcessing = false
        }

        controller.dismiss()
    }

    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        self.lastCompletion = completion
        self.paymentPopupProcessing = false

        let paymentMethodDictionary: NSMutableDictionary = [:]
        let token: NSMutableDictionary = [
            "paymentData": String(data: payment.token.paymentData, encoding: String.Encoding.utf8) ?? "",
            "transactionIdentifier": payment.token.transactionIdentifier,
            "paymentMethod": paymentMethodDictionary
        ];

        if payment.token.paymentMethod.displayName != nil {
            paymentMethodDictionary["displayName"] = payment.token.paymentMethod.displayName ?? ""
        }

//         if #available(iOS 13.4, *) {
//             if let secureElementPass = payment.token.paymentMethod.secureElementPass {
//                 let secureElementPassDictionary: NSMutableDictionary = [
//                     "deviceAccountNumberSuffix": secureElementPass.deviceAccountNumberSuffix,
//                     "deviceAccountIdentifier": secureElementPass.deviceAccountIdentifier,
//                     "primaryAccountIdentifier": secureElementPass.primaryAccountIdentifier,
//                     "primaryAccountNumberSuffix": secureElementPass.primaryAccountNumberSuffix,
//                 ]
//
//                 if secureElementPass.devicePassIdentifier != nil {
//                     secureElementPassDictionary["devicePassIdentifier"] = secureElementPass.devicePassIdentifier
//                 }
//
//                 if secureElementPass.pairedTerminalIdentifier != nil {
//                     secureElementPassDictionary["pairedTerminalIdentifier"] = secureElementPass.pairedTerminalIdentifier
//                 }
//
//                 paymentMethodDictionary["secureElementPass"] = secureElementPassDictionary;
//             }
//         }

        // TODO:
//        let shippingContactDictionary: NSMutableDictionary = [:]
//        if let shippingContact = payment.shippingContact {
//            if shippingContact.emailAddress != nil {
//                shippingContactDictionary["emailAddress"] = shippingContact.emailAddress
//            }
//
//            if shippingContact.phoneNumber != nil {
//                shippingContactDictionary["phoneNumber"] = shippingContact.phoneNumber
//            }
//        }

        self.savedCall?.resolve([
            "token": token,
//            "shippingContact": shippingContactDictionary
        ])

        self.savedCall = nil
    }
}
