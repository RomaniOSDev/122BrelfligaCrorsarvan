//
//  AppExternalURL.swift
//  122BrelfligaCrorsarvan
//

import Foundation

/// Legal and policy URLs. Replace placeholders with production endpoints when ready.
enum AppExternalURL {
    case privacyPolicy
    case termsOfUse

    var url: URL? {
        switch self {
        case .privacyPolicy:
            URL(string: "https://brelfliga122crorsarvan.site/privacy/68")
        case .termsOfUse:
            URL(string: "https://brelfliga122crorsarvan.site/terms/68")
        }
    }
}
