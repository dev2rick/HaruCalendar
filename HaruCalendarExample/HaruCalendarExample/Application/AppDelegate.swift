//
//  AppDelegate.swift
//  HaruCalendarExample
//
//  Created by rick on 9/22/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        
        config.delegateClass = SceneDelegate.self
        
        return config
    }
}

