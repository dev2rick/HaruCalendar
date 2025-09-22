//
//  SceneDelegate.swift
//  HaruCalendarExample
//
//  Created by rick on 9/22/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        let viewController = ViewController()
        
        window.rootViewController = viewController
        
        window.makeKeyAndVisible()
        
        self.window = window
    }
}
