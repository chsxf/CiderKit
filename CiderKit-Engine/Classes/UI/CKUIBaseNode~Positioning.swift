import CiderCSSKit

extension CKUIBaseNode {
    
    public var anchoredPosition: CKUIAnchoredPosition {
        get {
            guard let values = self.getStyleValues(key: CKUICSSAttributes.anchoredPosition) else {
                return CKUIAnchoredPosition()
            }
            return CKUIAnchoredPosition(values: values)
        }
        
        set { self.setStyleValues(key: CKUICSSAttributes.anchoredPosition, values: newValue.toCSSValues()) }
    }
    
    public var sizeDelta: CKUISizeDelta {
        get {
            guard let values = self.getStyleValues(key: CKUICSSAttributes.sizeDelta) else {
                return CKUISizeDelta()
            }
            return CKUISizeDelta(values: values)
        }
        
        set { self.setStyleValues(key: CKUICSSAttributes.sizeDelta, values: newValue.toCSSValues()) }
    }
    
    public var anchors: CKUIAnchors {
        get {
            guard let values = self.getStyleValues(key: CKUICSSAttributes.anchors) else {
                return CKUIAnchors()
            }
            return CKUIAnchors(values: values)
        }
        
        set {
            let values = newValue.toCSSValues()
            let expanded = CKUICSSAttributeExpanders.expandAnchorsUnchecked(values: values)!
            for entry in expanded {
                self.setStyleValues(key: entry.key, values: entry.value)
            }
        }
    }
    
    public var pivot: CKUIPivot {
        get {
            guard let values = self.getStyleValues(key: CSSAttributes.transformOrigin) else {
                return CKUIPivot(x: 0.5, y: 0.5)
            }
            return CKUIPivot(values: values)
        }
        
        set { self.setStyleValues(key: CSSAttributes.transformOrigin, values: newValue.toCSSValues()) }
    }
    
    public var padding: CKUIPadding {
        get {
            if let padding = self.getStyleValues(key: CSSAttributes.padding) {
                return CKUIPadding(values: padding)
            }
            
            let padding = [
                self.getStyleValue(key: CSSAttributes.paddingTop) ?? .length(0, .px),
                self.getStyleValue(key: CSSAttributes.paddingRight) ?? .length(0, .px),
                self.getStyleValue(key: CSSAttributes.paddingBottom) ?? .length(0, .px),
                self.getStyleValue(key: CSSAttributes.paddingLeft) ?? .length(0, .px)
            ]
            return CKUIPadding(values: padding)
        }
        
        set {
            let values = newValue.toCSSValues()
            self.setStyleValues(key: CSSAttributes.padding, values: values)
            self.setStyleValue(key: CSSAttributes.paddingTop, value: values[0])
            self.setStyleValue(key: CSSAttributes.paddingRight, value: values[1])
            self.setStyleValue(key: CSSAttributes.paddingBottom, value: values[2])
            self.setStyleValue(key: CSSAttributes.paddingLeft, value: values[3])
        }
    }

    public var zIndex: Int {
        get {
            guard case .number(let value) = self.getStyleValue(key: CSSAttributes.zIndex) else {
                return 1
            }
            return Int(value)
        }

        set { self.setStyleValue(key: CSSAttributes.zIndex, value: .number(Float(newValue))) }
    }

}
