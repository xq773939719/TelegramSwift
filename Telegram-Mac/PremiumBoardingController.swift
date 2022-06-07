//
//  PremiumBoardingController.swift
//  Telegram
//
//  Created by Mike Renoir on 10.05.2022.
//  Copyright © 2022 Telegram. All rights reserved.
//

import Cocoa
import TGUIKit
import SwiftSignalKit
import TelegramCore
import Postbox
import InAppPurchaseManager

enum PremiumLogEventsSource : Equatable {
    
    enum Subsource : String {
        case channels
        case channels_public
        case saved_gifs
        case stickers_faved
        case dialog_filters
        case dialog_filters_chats
        case dialog_filters_pinned
        case dialog_pinned
        case caption_length
        case upload_max_fileparts
        case dialogs_folder_pinned
        case accounts
        case about
    }
    
    case deeplink(String?)
    case settings
    case double_limits(Subsource)
    case more_upload
    case unique_reactions
    case premium_stickers
    case profile(PeerId)
    var value: String {
        switch self {
        case let .deeplink(ref):
            if let ref = ref {
                return "deeplink_" + ref
            } else {
                return "deeplink"
            }
        case .settings:
            return "settings"
        case let .double_limits(sub):
            return "double_limits__\(sub)"
        case .more_upload:
            return "more_upload"
        case .unique_reactions:
            return "unique_reactions"
        case .premium_stickers:
            return "premium_stickers"
        case let .profile(peerId):
            return "profile__\(peerId.id)"
        }
    }
    var subsource: String? {
        switch self {
        case let .double_limits(sub):
            return sub.rawValue
        default:
            return nil
        }
    }
    
}

enum PremiumLogEvents  {
    case promo_screen_show(PremiumLogEventsSource)
    case promo_screen_tap(PremiumValue)
    case promo_screen_accept
    case promo_screen_fail
    
    var value: String {
        switch self {
        case .promo_screen_show:
            return "promo_screen_show"
        case .promo_screen_tap:
            return "promo_screen_tap"
        case .promo_screen_accept:
            return "promo_screen_accept"
        case .promo_screen_fail:
            return "promo_screen_fail"
        }
    }
    
    
    func send(context: AccountContext) {

        let type = "premium.\(self.value)"
        switch self {
        case let .promo_screen_show(source):
            addAppLogEvent(postbox: context.account.postbox, time: Date().timeIntervalSince1970, type: type, peerId: context.peerId, data: [
                "premium_promo_order": context.premiumOrder.premiumValues.map { $0.rawValue },
                "source":source.value
            ])
        case let .promo_screen_tap(value):
            addAppLogEvent(postbox: context.account.postbox, time: Date().timeIntervalSince1970, type: type, peerId: context.peerId, data: [
                "item":value.rawValue
            ])
        case .promo_screen_fail, .promo_screen_accept:
            addAppLogEvent(postbox: context.account.postbox, time: Date().timeIntervalSince1970, type: type, peerId: context.peerId, data: [:])
        }

    }
}



private final class Arguments {
    let context: AccountContext
    let showTerms:()->Void
    let showPrivacy:()->Void
    let openInfo:(PeerId, Bool, MessageId?, ChatInitialAction?)->Void
    let openFeature:(PremiumValue)->Void
    init(context: AccountContext, showTerms: @escaping()->Void, showPrivacy:@escaping()->Void, openInfo:@escaping(PeerId, Bool, MessageId?, ChatInitialAction?)->Void, openFeature:@escaping(PremiumValue)->Void) {
        self.context = context
        self.showPrivacy = showPrivacy
        self.showTerms = showTerms
        self.openInfo = openInfo
        self.openFeature = openFeature
    }
}

enum PremiumValue : String {
    case double_limits
    case more_upload
    case faster_download
    case voice_to_text
    case no_ads
    case unique_reactions
    case premium_stickers
    case advanced_chat_management
    case profile_badge
    case animated_userpics
    
    var gradient: [NSColor] {
        switch self {
        case .double_limits:
            return [NSColor(rgb: 0xF17D2F)]
        case .more_upload:
            return [NSColor(rgb: 0xE9574A)]
        case .faster_download:
            return [NSColor(rgb: 0xD84C7D)]
        case .voice_to_text:
            return [NSColor(rgb: 0xc14998)]
        case .no_ads:
            return [NSColor(rgb: 0xC258B7)]
        case .unique_reactions:
            return [NSColor(rgb: 0xA868FC)]
        case .premium_stickers:
            return [NSColor(rgb: 0x9279FF)]
        case .advanced_chat_management:
            return [NSColor(rgb: 0x7561eb)]
        case .profile_badge:
            return [NSColor(rgb: 0x758EFF)]
        case .animated_userpics:
            return [NSColor(rgb: 0x59A4FF)]
        }
    }
    
    var icon: CGImage {
        let image = self.image
        let size = image.backingSize
        let img = generateImage(size, contextGenerator: { size, ctx in
            ctx.clear(size.bounds)
            ctx.clip(to: size.bounds, mask: image)
            
            let colors = gradient.compactMap { $0.cgColor } as NSArray

            if gradient.count == 1 {
                ctx.setFillColor(gradient[0].cgColor)
                ctx.fill(size.bounds)
            } else {
                let delta: CGFloat = 1.0 / (CGFloat(colors.count) - 1.0)
                
                var locations: [CGFloat] = []
                for i in 0 ..< colors.count {
                    locations.append(delta * CGFloat(i))
                }
                let colorSpace = deviceColorSpace
                let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: &locations)!
                
                ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: size.width, y: size.height), options: CGGradientDrawingOptions())
            }

            
            
        })!
        
        return generateImage(size, contextGenerator: { size, ctx in
            ctx.clear(size.bounds)
            
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(size.bounds.insetBy(dx: 2, dy: 2))
            
            ctx.draw(img, in: size.bounds)
        })!
    }
    
    var image: CGImage {
        switch self {
        case .double_limits:
            return NSImage(named: "Icon_Premium_Boarding_X2")!.precomposed(theme.colors.accent)
        case .more_upload:
            return NSImage(named: "Icon_Premium_Boarding_Files")!.precomposed(theme.colors.accent)
        case .faster_download:
            return NSImage(named: "Icon_Premium_Boarding_Speed")!.precomposed(theme.colors.accent)
        case .voice_to_text:
            return NSImage(named: "Icon_Premium_Boarding_Voice")!.precomposed(theme.colors.accent)
        case .no_ads:
            return NSImage(named: "Icon_Premium_Boarding_Ads")!.precomposed(theme.colors.accent)
        case .unique_reactions:
            return NSImage(named: "Icon_Premium_Boarding_Reactions")!.precomposed(theme.colors.accent)
        case .premium_stickers:
            return NSImage(named: "Icon_Premium_Boarding_Stickers")!.precomposed(theme.colors.accent)
        case .advanced_chat_management:
            return NSImage(named: "Icon_Premium_Boarding_Chats")!.precomposed(theme.colors.accent)
        case .profile_badge:
            return NSImage(named: "Icon_Premium_Boarding_Badge")!.precomposed(theme.colors.accent)
        case .animated_userpics:
            return NSImage(named: "Icon_Premium_Boarding_Profile")!.precomposed(theme.colors.accent)
        }
    }
    
    func title(_ limits: PremiumLimitConfig) -> String {
        switch self {
        case .double_limits:
            return strings().premiumBoardingDoubleTitle
        case .more_upload:
            return strings().premiumBoardingFileSizeTitle(String.prettySized(with: limits.upload_max_fileparts_premium, afterDot: 0, round: true))
        case .faster_download:
            return strings().premiumBoardingDownloadTitle
        case .voice_to_text:
            return strings().premiumBoardingVoiceTitle
        case .no_ads:
            return strings().premiumBoardingNoAdsTitle
        case .unique_reactions:
            return strings().premiumBoardingReactionsTitle
        case .premium_stickers:
            return strings().premiumBoardingStickersTitle
        case .advanced_chat_management:
            return strings().premiumBoardingChatsTitle
        case .profile_badge:
            return strings().premiumBoardingBadgeTitle
        case .animated_userpics:
            return strings().premiumBoardingAvatarTitle
        }
    }
    func info(_ limits: PremiumLimitConfig) -> String {
        switch self {
        case .double_limits:
            return strings().premiumBoardingDoubleInfo("\(limits.channels_limit_premium)", "\(limits.dialog_filters_limit_premium)", "\(limits.dialog_pinned_limit_premium)", "\(limits.channels_public_limit_premium)")
        case .more_upload:
            return strings().premiumBoardingFileSizeInfo(String.prettySized(with: limits.upload_max_fileparts_default, afterDot: 0, round: true), String.prettySized(with: limits.upload_max_fileparts_premium, afterDot: 0, round: true))
        case .faster_download:
            return strings().premiumBoardingDownloadInfo
        case .voice_to_text:
            return strings().premiumBoardingVoiceInfo
        case .no_ads:
            return strings().premiumBoardingNoAdsInfo
        case .unique_reactions:
            return strings().premiumBoardingReactionsInfo
        case .premium_stickers:
            return strings().premiumBoardingStickersInfo
        case .advanced_chat_management:
            return strings().premiumBoardingChatsInfo
        case .profile_badge:
            return strings().premiumBoardingBadgeInfo
        case .animated_userpics:
            return strings().premiumBoardingAvatarInfo
        }
    }
}


private struct State : Equatable {
    var values:[PremiumValue] = [.double_limits, .more_upload, .faster_download, .voice_to_text, .no_ads, .unique_reactions, .premium_stickers, .advanced_chat_management, .profile_badge, .animated_userpics]
    let source: PremiumLogEventsSource
    
    var premiumProduct: InAppPurchaseManager.Product?
    var isPremium: Bool
    var peer: PeerEquatable?
    var premiumConfiguration: PremiumPromoConfiguration
    
    var canMakePayment: Bool
}



private func entries(_ state: State, arguments: Arguments) -> [InputDataEntry] {
    var entries:[InputDataEntry] = []
    
    var sectionId:Int32 = 0
    var index: Int32 = 0
    
    entries.append(.sectionId(sectionId, type: .customModern(35)))
    sectionId += 1

    
    entries.append(.custom(sectionId: sectionId, index: index, value: .none, identifier: .init("header"), equatable: InputDataEquatable(state), comparable: nil, item: { initialSize, stableId in
        return PremiumBoardingHeaderItem(initialSize, stableId: stableId, isPremium: state.isPremium, peer: state.peer?.peer, viewType: .legacy)
    }))
    index += 1
    
    for (i, value) in state.values.enumerated() {
        let viewType = bestGeneralViewType(state.values, for: i)
        entries.append(.custom(sectionId: sectionId, index: index, value: .none, identifier: .init(value.rawValue), equatable: InputDataEquatable(value), comparable: nil, item: { initialSize, stableId in
            return PremiumBoardingRowItem(initialSize, stableId: stableId, viewType: viewType, value: value, limits: arguments.context.premiumLimits, isLast: false, callback: arguments.openFeature)
        }))
        index += 1
    }
    
    entries.append(.sectionId(sectionId, type: .customModern(15)))
    sectionId += 1
   
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(strings().premiumBoardingAboutTitle.uppercased()), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1
    
    
    entries.append(.custom(sectionId: sectionId, index: index, value: .none, identifier: .init("about"), equatable: nil, comparable: nil, item: { initialSize, stableId in
        return GeneralBlockTextRowItem(initialSize, stableId: stableId, viewType: .singleItem, text: strings().premiumBoardingAboutText, font: .normal(.text), insets: NSEdgeInsets(left: 20, right: 20))
    }))
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .markdown(strings().premiumBoardingAboutTos, linkHandler: { content in
        if content == "privacy" {
            arguments.showPrivacy()
        } else if content == "terms" {
            arguments.showTerms()
        }
    }), data: .init(color: theme.colors.listGrayText, viewType: .textBottomItem)))
    index += 1
    
    entries.append(.sectionId(sectionId, type: .customModern(15)))
    sectionId += 1

   
    
    return entries
}

private final class PremiumBoardingView : View {
    
    private final class AcceptView : Control {
        private let gradient: PremiumGradientView = PremiumGradientView(frame: .zero)
        private let shimmer = ShimmerEffectView()
        private let textView = TextView()
        private let container = View()
        required init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            addSubview(gradient)
            addSubview(shimmer)
            shimmer.isStatic = true
            container.addSubview(textView)
            addSubview(container)
            scaleOnClick = true
            
            textView.userInteractionEnabled = false
            textView.isSelectable = false
        }
        
        override func layout() {
            super.layout()
            gradient.frame = bounds
            shimmer.frame = bounds
            container.center()
            textView.center()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func update(animated: Bool, state: State) -> NSSize {
            let price: String
            if let product = state.premiumProduct {
                price = product.price
            } else {
                price = formatCurrencyAmount(state.premiumConfiguration.monthlyAmount, currency: state.premiumConfiguration.currency)
            }
            let text: String
            if state.canMakePayment {
                text = strings().premiumBoardingSubscribe(price)
            } else {
                text = strings().premiumBoardingPaymentNotAvailalbe
            }
            
            let layout = TextViewLayout(.initialize(string: text, color: NSColor.white, font: .medium(.text)))
            layout.measure(width: .greatestFiniteMagnitude)
            textView.update(layout)
                        
            container.setFrameSize(layout.layoutSize)
            
            let size = NSMakeSize(container.frame.width + 100, 40)
            
            shimmer.updateAbsoluteRect(size.bounds, within: size)
            shimmer.update(backgroundColor: .clear, foregroundColor: .clear, shimmeringColor: NSColor.white.withAlphaComponent(0.3), shapes: [.roundedRect(rect: size.bounds, cornerRadius: size.height / 2)], horizontal: true, size: size)

            needsLayout = true
            
            self.userInteractionEnabled = state.canMakePayment
            
            self.alphaValue = state.canMakePayment ? 1.0 : 0.7
            
            return size
        }
    }
    
    final class HeaderView: View {
        let dismiss = ImageButton()
        private let container = View()
        private let titleView = TextView()
        required init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            addSubview(container)
            addSubview(dismiss)
            
            dismiss.scaleOnClick = true
            dismiss.autohighlight = false
            
            dismiss.set(image: theme.icons.modalClose, for: .Normal)
            dismiss.sizeToFit()
            
            titleView.userInteractionEnabled = false
            titleView.isSelectable = false
            titleView.isEventLess = true
            
            container.backgroundColor = theme.colors.background
            container.border = [.Bottom]

            let layout = TextViewLayout(.initialize(string: strings().premiumBoardingTitle, color: theme.colors.text, font: .medium(.header)))
            layout.measure(width: 300)
            
            titleView.update(layout)
            container.addSubview(titleView)
        }
        
        func update(isHidden: Bool, animated: Bool) {
            container.change(opacity: isHidden ? 0 : 1, animated: animated)
        }
        
        override func layout() {
            super.layout()
            dismiss.centerY(x: 10)
            container.frame = bounds
            titleView.center()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    
    private let headerView: HeaderView = HeaderView(frame: .zero)
    let tableView = TableView()
    private var bottomView: View?
    private let bottomBorder = View()
    private let acceptView = AcceptView(frame: .zero)
    private let statusView = TextView()
    
    private let containerView = View()
    private var fadeView: View?
    
    var dismiss:(()->Void)?
    var accept:(()->Void)?
    
    private var state: State?

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        containerView.addSubview(tableView)
        containerView.addSubview(headerView)
        addSubview(containerView)
        
        tableView.getBackgroundColor = {
            theme.colors.listBackground
        }
                
        bottomBorder.backgroundColor = theme.colors.border
        
        statusView.isSelectable = false
        
        tableView.addScroll(listener: TableScrollListener(dispatchWhenVisibleRangeUpdated: false, { [weak self] position in
            self?.updateScroll(position, animated: true)
        }))
        
        headerView.dismiss.set(handler: { [weak self] _ in
            self?.dismiss?()
        }, for: .Click)
        
        acceptView.set(handler: { [weak self] _ in
            self?.accept?()
        }, for: .Click)
    }
    
    private func updateScroll(_ scroll: ScrollPosition, animated: Bool) {
        let offset = scroll.rect.minY - tableView.frame.height
        
        if scroll.rect.minY >= tableView.listHeight {
            bottomBorder.change(opacity: 0, animated: animated)
            bottomView?.backgroundColor = theme.colors.listBackground
            if animated {
                bottomView?.layer?.animateBackground()
            }
        } else {
            bottomBorder.change(opacity: 1, animated: animated)
            bottomView?.backgroundColor = theme.colors.background
            if animated {
                bottomView?.layer?.animateBackground()
            }
        }
        
        headerView.update(isHidden: offset <= 127, animated: animated)
    }
    
    override func layout() {
        super.layout()
        updateLayout(size: self.frame.size, transition: .immediate)
    }
    
    var bottomHeight: CGFloat {
        if let state = self.state {
            if state.isPremium {
                return statusView.frame.height + 20
            } else {
                return acceptView.frame.height + 20
            }
        } else {
            return 0
        }
    }
    
    func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(view: headerView, frame: NSMakeRect(0, 0, size.width, 50))
        transition.updateFrame(view: containerView, frame: bounds)
        
        transition.updateFrame(view: tableView, frame: NSMakeRect(0, 0, size.width, size.height - bottomHeight))
        if let bottomView = bottomView {
            transition.updateFrame(view: bottomView, frame: NSMakeRect(0, tableView.frame.maxY, size.width, bottomHeight))
            
            transition.updateFrame(view: acceptView, frame: bottomView.focus(acceptView.frame.size))
            transition.updateFrame(view: statusView, frame: bottomView.focus(statusView.frame.size))
            
            transition.updateFrame(view: bottomBorder, frame: NSMakeRect(0, 0, bottomView.frame.width, .borderSize))
        }
        
        if let controller = self.currentController {
            transition.updateFrame(view: controller.view, frame: bounds)
        }
    }
    
    func contentSize(maxSize size: NSSize) -> NSSize {
        return NSMakeSize(size.width, min(min(headerView.frame.height + tableView.listHeight + bottomHeight, 528), size.height))
    }
    
    func update(animated: Bool, arguments: Arguments, state: State) {
        let previousState = self.state
        self.state = state
        let size = acceptView.update(animated: animated, state: state)
        acceptView.setFrameSize(size)
        acceptView.layer?.cornerRadius = size.height / 2
        let transition: ContainedViewLayoutTransition
        if animated {
            transition = .animated(duration: 0.2, curve: .easeOut)
        } else {
            transition = .immediate
        }
        
        
        let attr = ChatMessageItem.applyMessageEntities(with: [TextEntitiesMessageAttribute(entities: state.premiumConfiguration.statusEntities)], for: state.premiumConfiguration.status, message: nil, context: arguments.context, fontSize: 13, openInfo: arguments.openInfo)
        
        let statusLayout = TextViewLayout(attr, alignment: .center)
        statusLayout.measure(width: frame.width - 40)
        statusLayout.interactions = globalLinkExecutor
        
        self.statusView.update(statusLayout)
        
        if state.isPremium != previousState?.isPremium {
            let bottomView = View(frame: NSMakeRect(0, frame.height - bottomHeight, frame.width, bottomHeight))
            containerView.addSubview(bottomView)
            
            if state.isPremium {
                bottomView.addSubview(statusView)
            } else {
                bottomView.addSubview(acceptView)
            }
            bottomView.addSubview(bottomBorder)
            
            if let view = self.bottomView {
                performSubviewRemoval(view, animated: animated)
            }
            
            self.bottomView = bottomView
            
            if animated {
                bottomView.layer?.animateAlpha(from: 0, to: 1, duration: 0.2)
            }
        }
        
        self.updateScroll(tableView.scrollPosition().current, animated: false)

        updateLayout(size: frame.size, transition: transition)
    }
    
    func makeAcceptView() -> Control {
        let acceptView = AcceptView(frame: .zero)
        if let state = self.state {
            let size = acceptView.update(animated: false, state: state)
            acceptView.setFrameSize(size)
        }
        acceptView.set(handler: { [weak self] _ in
            self?.accept?()
        }, for: .Click)
        
        return acceptView
    }
    
    private var currentController: ViewController?
    
    private let duration: Double = 0.4
    
    func append(_ controller: ViewController, animated: Bool) {
        controller._frameRect = self.bounds
        addSubview(controller.view)

        if animated {
            controller.view.layer?.animatePosition(from: NSMakePoint(frame.width, 0), to: .zero, duration: duration, timingFunction: .spring)
            self.containerView.layer?.animatePosition(from: .zero, to: NSMakePoint(-30, 0), duration: duration, timingFunction: .spring)
            
            applyFade(from: 0, to: 1)

        }
        
        self.currentController = controller
    }
    
    private func applyFade(from: Double, to: Double) {
        let fadeView = View()
        fadeView.backgroundColor = theme.colors.blackTransparent
        fadeView.frame = bounds
        addSubview(fadeView, positioned: .above, relativeTo: containerView)
        
        fadeView.layer?.animateAlpha(from: from, to: to, duration: duration - 0.05, removeOnCompletion: false, completion: { [weak fadeView] _ in
            fadeView?.removeFromSuperview()
        })
    }
    
    func stackBack(animated: Bool) -> Bool {
        if let controller = currentController {
            controller.view.layer?.animatePosition(from: .zero, to: NSMakePoint(frame.width, 0), duration: duration, timingFunction: .spring, removeOnCompletion: false, completion: { [weak controller, weak self] _ in
                controller?.view.removeFromSuperview()
                self?.currentController = nil
            })

            self.containerView.layer?.animatePosition(from: NSMakePoint(-30, 0), to: .zero, duration: duration, timingFunction: .spring)
            
            applyFade(from: 1, to: 0)
            
            return true
        } else {
            return false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PremiumBoardingController : ModalViewController {

    private let context: AccountContext
    private let source: PremiumLogEventsSource
    init(context: AccountContext, source: PremiumLogEventsSource = .settings) {
        self.context = context
        self.source = source
        super.init(frame: NSMakeRect(0, 0, 350, 300))
    }
    
    override func measure(size: NSSize) {
        updateSize(false)
    }
    
    func updateSize(_ animated: Bool) {
        if let contentSize = self.modal?.window.contentView?.frame.size {
            self.modal?.resize(with: genericView.contentSize(maxSize: NSMakeSize(350, contentSize.height - 80)), animated: animated)
        }
    }
    
    override var dynamicSize: Bool {
        return true
    }
    
    private var genericView: PremiumBoardingView {
        return self.view as! PremiumBoardingView
    }
    
    override func viewClass() -> AnyClass {
        return PremiumBoardingView.self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let inAppPurchaseManager = context.sharedContext.inAppPurchaseManager
        
        let actionsDisposable = DisposableSet()
        let paymentDisposable = MetaDisposable()
        let activationDisposable = MetaDisposable()
        let context = self.context
        let source = self.source
        
        PremiumLogEvents.promo_screen_show(source).send(context: context)
        
        let close: ()->Void = {
            closeAllModals()
        }

        var canMakePayment: Bool = true
        #if APP_STORE || DEBUG
        canMakePayment = inAppPurchaseManager.canMakePayments()
        #endif
        
        let initialState = State(values: context.premiumOrder.premiumValues, source: source, isPremium: context.isPremium, premiumConfiguration: PremiumPromoConfiguration.defaultValue, canMakePayment: canMakePayment)
        
        let statePromise: ValuePromise<State> = ValuePromise(ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify (f))
        }
        
        let arguments = Arguments(context: context, showTerms: {
            
        }, showPrivacy: {
            
        }, openInfo: { peerId, _, _, initialAction in
            var updated: ChatInitialAction? = initialAction
            switch initialAction {
            case let .start(parameter, _):
                updated = .start(parameter: parameter, behavior: .automatic)
            default:
                break
            }
            let controller = ChatController(context: context, chatLocation: .peer(peerId), initialAction: updated)
            context.bindings.rootNavigation().push(controller)
            
            close()
        }, openFeature: { [weak self] value in
            guard let strongSelf = self else {
                return
            }
            switch value {
            case .double_limits:
                strongSelf.genericView.append(PremiumBoardingDoubleController(context, back: {
                    _ = strongSelf.escapeKeyAction()
                }, acceptView: stateValue.with { !$0.isPremium } ? strongSelf.genericView.makeAcceptView() : nil), animated: true)
            default:
                break
            }
        })
        
        let peer: Signal<Peer?, NoError>
        switch source {
        case let .profile(peerId):
            peer = context.account.postbox.transaction { $0.getPeer(peerId) }
        default:
            peer = .single(nil)
        }
        
        
        
        let premiumPromo = context.engine.data.get(TelegramEngine.EngineData.Item.Configuration.PremiumPromo())
        |> deliverOnMainQueue
        

        actionsDisposable.add(combineLatest(
            queue: Queue.mainQueue(),
            inAppPurchaseManager.availableProducts,
            premiumPromo,
            context.account.postbox.peerView(id: context.account.peerId)
            |> map { view -> Bool in
                return view.peers[view.peerId]?.isPremium ?? false
            }, peer).start(next: { products, promoConfiguration, isPremium, peer in
                updateState { current in
                    var current = current
                    current.premiumProduct = products.first
                    current.isPremium = isPremium
                    current.premiumConfiguration = promoConfiguration
                    if let peer = peer {
                        current.peer = .init(peer)
                    }
                    
                    return current
                }
                for (_, video) in promoConfiguration.videos {
                    actionsDisposable.add(preloadVideoResource(postbox: context.account.postbox, resourceReference: .standalone(resource: video.resource), duration: 3.0).start())
                }
        }))

        
        let stateSignal = statePromise.get() |> deliverOnPrepareQueue |> map { state in
            return (InputDataSignalValue(entries: entries(state, arguments: arguments)), state)
        }
        
        let previous: Atomic<[AppearanceWrapperEntry<InputDataEntry>]> = Atomic(value: [])
        let initialSize = self.atomicSize
        
        
        let inputArguments = InputDataArguments(select: { _, _ in }, dataUpdated: {
            
        })
        
        
        

        
        let signal: Signal<(TableUpdateTransition, State), NoError> = combineLatest(queue: .mainQueue(), appearanceSignal, stateSignal) |> mapToQueue { appearance, state in
            let entries = state.0.entries.map({AppearanceWrapperEntry(entry: $0, appearance: appearance)})
            return prepareInputDataTransition(left: previous.swap(entries), right: entries, animated: state.0.animated, searchState: state.0.searchState, initialSize: initialSize.modify{ $0 }, arguments: inputArguments, onMainQueue: true)
            |> map {
                ($0, state.1)
            }
        } |> deliverOnMainQueue |> afterDisposed {
            previous.swap([])
        }
        
        actionsDisposable.add(signal.start(next: { [weak self] transition in
            self?.genericView.tableView.merge(with: transition.0)
            self?.genericView.update(animated: transition.0.animated, arguments: arguments, state: transition.1)
            self?.updateSize(transition.0.animated)
            self?.readyOnce()
        }))
        
        
        
        let buyNonStore = {
            if let slug = context.premiumBuyConfig.invoiceSlug {
                
                let signal = showModalProgress(signal: context.engine.payments.fetchBotPaymentInvoice(source: .slug(slug)), for: context.window)

                _ = signal.start(next: { invoice in
                    showModal(with: PaymentsCheckoutController(context: context, source: .slug(slug), invoice: invoice, completion: { status in
                        switch status {
                        case .paid:
                            PlayConfetti(for: context.window)
                            close()
                        case .cancelled:
                            break
                        case .failed:
                            break
                        }
                    }), for: context.window)
                }, error: { error in
                    showModalText(for: context.window, text: strings().paymentsInvoiceNotExists)
                })
            } else if let username = context.premiumBuyConfig.botUsername {
                let inApp = inApp(for: "https://t.me/\(username)?start=\(source.value)".nsstring, context: context, openInfo: arguments.openInfo)
                execute(inapp: inApp)
                close()
            }
        }
        
        
        let buyAppStore = {
            
            let premiumProduct = stateValue.with { $0.premiumProduct }

            guard let premiumProduct = premiumProduct else {
                buyNonStore()
                return
            }
            
            let lockModal = PremiumLockModalController()
            
            var needToShow = true
            delay(0.2, closure: {
                if needToShow {
                    showModal(with: lockModal, for: context.window)
                }
            })
            
            paymentDisposable.set((inAppPurchaseManager.buyProduct(premiumProduct, account: context.account)
            |> deliverOnMainQueue).start(next: { [weak lockModal] status in
                
                lockModal?.close()
                needToShow = false
                
                if case let .purchased(transaction) = status, let id = transaction.transactionIdentifier {
                                        
                                        
                    let activate = showModalProgress(signal: context.engine.payments.assignAppStoreTransaction(transactionId: id), for: context.window)
                    activationDisposable.set(activate.start(error: { _ in
                        showModalText(for: context.window, text: strings().errorAnError)
                        inAppPurchaseManager.finishTransaction(transaction)
                    }, completed: {
                        close()
                        inAppPurchaseManager.finishTransaction(transaction)
                        delay(0.2, closure: {
                            PlayConfetti(for: context.window)
                            showModalText(for: context.window, text: strings().premiumBoardingAppStoreSuccess)
                        })
                    }))
                }
            }, error: { [weak lockModal] error in
                
                lockModal?.close()
                showModalText(for: context.window, text: strings().premiumBoardingAppStoreCancelled)
                
                switch error {
                case let .generic(transaction):
                    addAppLogEvent(postbox: context.account.postbox, type: PremiumLogEvents.promo_screen_fail.value)
                    if let transaction = transaction {
                        inAppPurchaseManager.finishTransaction(transaction)
                    }
                }
                
            }))
        }
        
        
        genericView.dismiss = close
        genericView.accept = {
            
            addAppLogEvent(postbox: context.account.postbox, type: PremiumLogEvents.promo_screen_accept.value)
            
            #if APP_STORE || DEBUG
            buyAppStore()
            #else
            buyNonStore()
            #endif
        }
                
        self.onDeinit = {
            actionsDisposable.dispose()
        }
    }
    
    override func escapeKeyAction() -> KeyHandlerResult {
        if genericView.stackBack(animated: true) {
            return .invoked
        } else {
            return super.escapeKeyAction()
        }
    }
}




