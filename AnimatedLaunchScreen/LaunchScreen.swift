//
//  LaunchScreen.swift
//  AnimatedLaunchScreen
//
//  Created by Ali Soner Inceoglu on 12.11.26.
//

import SwiftUI

struct LaunchConfig {
    var logo: Image = .init(.launchIcon)
    var tint: Color = .black
    var initialDelay: CGFloat = 0.35
    /// Only for OnBoardingView
    var iconPadding: CGFloat = 30
    var iconSize: CGSize = .init(width: 150, height: 150)
    var iconRadius: CGFloat = 45
}

struct LaunchScreenModifier<OnBoarding: View>: ViewModifier {
    var config: LaunchConfig
    var showOnBoarding: Bool
    @ContentBuilder var onBoarding: OnBoarding
    /// View properties
    @State private var addSplash = false
    
    func body(content: Content) -> some View {
        content
            .onAppear(perform: toggleSplash)
            .macFullScreenCover(isPresented: $addSplash) {
                ZStack {
                    if showOnBoarding {
                        LaunchScreenWithOnBoarding(config: config) {
                            onBoarding
                        }
                    } else {
                        LaunchScreenOnly(config: config)
                            .presentationBackground(.clear)
                    }
                }
            }
    }
    
    private func toggleSplash() {
        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                addSplash.toggle()
            }
        }
    }
}

extension View {
    @ContentBuilder
    func splashScreen<OnBoarding: View>(
        config: LaunchConfig,
        showOnBoarding: Bool,
        @ContentBuilder onBoarding: () -> OnBoarding
        
    ) -> some View {
        self
            .modifier(LaunchScreenModifier(
                config: config,
                showOnBoarding: showOnBoarding,
                onBoarding: onBoarding
            ))
    }
}

private struct LaunchScreenWithOnBoarding<Content: View>: View {
    var config: LaunchConfig
    @ContentBuilder var onBoarding: Content
    /// View Properties
    @State private var pushIcon = false
    @State private var animateIcon = false
    
    var body: some View {
        let layout = animateIcon ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(ZStackLayout(alignment: .bottom))
        
        layout {
            ZStack {
                RoundedRectangle(cornerRadius: animateIcon ? config.iconRadius : 0)
                    .fill(config.tint)
                
                /// Original logo to match the native launch screen size
                config.logo
                    .frame(
                        width: animateIcon ? config.iconSize.width : nil,
                        height: animateIcon ? config.iconSize.height : nil
                    )
                    .animation(.none) {
                        $0.opacity(animateIcon ? 0 : 1)
                    }
                    .overlay {
                        /// Resizable logo for custom sizing
                        config.logo
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .animation(.none) {
                                $0.opacity(animateIcon ? 1 : 0)
                            }
                            .padding(animateIcon ? config.iconPadding : 0)
                    }
            }
            .frame(
                width: animateIcon ? config.iconSize.width : nil,
                height: animateIcon ? config.iconSize.height : nil
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: pushIcon ? 100 : 0)
            .zIndex(1)
            .geometryGroup()
            .ignoresSafeArea()
            
            /// OnBoarding View
            onBoarding
                .compositingGroup()
                .visualEffect { [animateIcon] content, proxy in
                    return content
                        .blur(radius: animateIcon ? 0 : 15)
                        .opacity(animateIcon ? 1 : 0)
                        .offset(y: animateIcon ? 0 : proxy.size.height)
                }
                .zIndex(0)
        }
        .task {
            guard !animateIcon else { return }
            
            do {
               try await Task.sleep(for: .seconds(config.initialDelay))
           } catch {
               return
           }
            
            withAnimation(.bouncy(duration: 0.5, extraBounce: 0.05)) {
                pushIcon = true
                animateIcon = true
            }
            
            do {
                try await Task.sleep(for: .seconds(0.15))
            } catch {
                return
            }

            
            withAnimation(.bouncy(duration: 0.4)) {
                pushIcon = false
            }
        }
    }
}

private struct LaunchScreenOnly: View {
    var config: LaunchConfig
    /// View Properties
    @State private var scaleUp = false
    @State private var scaleDown = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .overlay {
                GeometryReader {
                    let scaleFactor: CGFloat = 4
                    
                    let size = $0.size.applying(.init(scaleX: scaleFactor, y: scaleFactor))
                    
                    Rectangle()
                        .fill(config.tint)
                        /// Masking Logo Image
                        .mask {
                            /// Inverse Mask
                            Rectangle()
                                .overlay {
                                     LogoView(true, size: size)
                                }
                        }
                        .overlay {
                            LogoView(false, size: size)
                        }
                }
            }
            .ignoresSafeArea()
            .task {
                guard !scaleDown else { return }
                
                /// Bounce Down
                try? await Task.sleep(for: .seconds(config.initialDelay))
                withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                    scaleDown = true
                }
                
                /// Scale and Mask Up
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(.interpolatingSpring(duration: 0.6, bounce: 0, initialVelocity: 0)) {
                    scaleUp = true
                }
                
                /// Dismiss Splash Screen
                try? await Task.sleep(for: .seconds(0.6))
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    dismiss()
                }
            }
    }
    
    
    /// Logo View
    @ContentBuilder
    private func LogoView(_ isMask: Bool, size: CGSize) -> some View {
        config.logo
            .blendMode(isMask ? .destinationOut : .normal)
            .scaleEffect(scaleDown ? 0.8 : 1)
            .visualEffect { [scaleUp] content, proxy in
                let imageSize = proxy.size
                let scale = max(
                    size.width / imageSize.width,
                    size.height / imageSize.height
                )
                
                return content
                    .scaleEffect(scaleUp ? scale : 1)
                    .opacity(isMask ? (scaleUp ? 1 : 0) : (scaleUp ? 0 : 1))
            }
    }
}

#Preview {
    ContentView()
}
