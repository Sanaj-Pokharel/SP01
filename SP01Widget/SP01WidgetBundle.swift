//
//  SP01WidgetBundle.swift
//  SP01Widget
//
//  Created by Sanaj Pokharel on 31/1/2026.
//

import WidgetKit
import SwiftUI

@main
struct SP01WidgetBundle: WidgetBundle {
    var body: some Widget {
        SP01Widget()
        SP01WidgetControl()
        SP01WidgetLiveActivity()
    }
}
