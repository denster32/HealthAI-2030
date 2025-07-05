import HealthAI2030Core
import HealthAI2030Core
import HealthAI2030Core
import HealthAI2030Core
public protocol HealthDashboardPlugin {
    var pluginName: String { get }
    func contribute(to dashboardVM: HealthDashboardViewModel)
}
