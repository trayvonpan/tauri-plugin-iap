import SwiftRs
import Tauri
import UIKit
import WebKit

class IapPlugin: Plugin {
}

@_cdecl("init_plugin_iap")
func initPlugin() -> Plugin {
  return IapPlugin()
}
