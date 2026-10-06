import Foundation

struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let price: Double
    let description: String
    let specs: KeyValuePairs<String, String>

    /// Asset catalog image name.
    var imageName: String { id }

    static func == (lhs: Product, rhs: Product) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Product {
    static func find(_ id: String) -> Product? { catalog.first { $0.id == id } }

    /// A small static catalog. In a real app this comes from your backend.
    static let catalog: [Product] = [
        Product(
            id: "prod_081", name: "Electronics Starter Kit", category: "Kits", price: 144.00,
            description: "Everything to start with electronics: components, tools and guided projects. Perfect for learning.",
            specs: ["Level": "Beginner", "Components": "200+", "Projects": "15+", "Guide": "Included"]
        ),
        Product(
            id: "prod_005", name: "Digital Multimeter DM-200", category: "Tools", price: 154.00,
            description: "Auto-ranging, true RMS and a high-contrast display for accurate measurements.",
            specs: ["Model": "DM-200", "Display": "LCD", "Auto-range": "Yes", "True RMS": "Yes"]
        ),
        Product(
            id: "prod_025", name: "Microcontroller Board MCU-32", category: "Components", price: 45.00,
            description: "A powerful board with built-in Wi-Fi and Bluetooth, USB-C and plenty of GPIO.",
            specs: ["Model": "MCU-32", "Core": "ARM Cortex", "Flash": "4 MB", "GPIO": "40 pins"]
        ),
        Product(
            id: "prod_001", name: "Precision Screwdriver Set, 64 pcs", category: "Tools", price: 82.99,
            description: "Professional-grade bits with magnetic tips, an ergonomic handle and an organized case.",
            specs: ["Pieces": "64", "Material": "S2 steel", "Handle": "Ergonomic grip", "Case": "Aluminum"]
        ),
        Product(
            id: "prod_098", name: "Robot Arm Kit 6-DOF", category: "Kits", price: 177.99,
            description: "Learn robotics and automation with a programmable six-axis arm.",
            specs: ["Axes": "6", "Control": "Arduino / Pi", "Reach": "30 cm", "Payload": "500 g"]
        ),
        Product(
            id: "prod_033", name: "OLED Display 0.96\"", category: "Components", price: 31.00,
            description: "A high-contrast blue OLED for embedded projects, with an I2C interface and a wide viewing angle.",
            specs: ["Size": "0.96\"", "Resolution": "128 × 64", "Interface": "I2C", "Driver": "SSD1306"]
        ),
        Product(
            id: "prod_009", name: "Soldering Station SS-60W", category: "Tools", price: 112.99,
            description: "Temperature-controlled station with a digital display, quick heat-up and interchangeable tips.",
            specs: ["Power": "60 W", "Temperature": "200–480 °C", "Heat-up": "< 10 s", "Tips": "5 included"]
        ),
        Product(
            id: "prod_069", name: "Breadboard, 830 Points", category: "Accessories", price: 18.99,
            description: "Solderless breadboard for rapid prototyping, with durable construction and clear labels.",
            specs: ["Points": "830", "Material": "ABS", "Binding posts": "Yes", "Labels": "Numbered"]
        ),
    ]

    /// Products to recommend on this product's page.
    ///
    /// - `same_category`: products from the same category first, then the rest.
    /// - `similar_price`: the products closest in price.
    func recommendations(strategy: String, count: Int) -> [Product] {
        let others = Product.catalog.filter { $0.id != id }
        let ranked: [Product]
        switch strategy {
        case "similar_price":
            ranked = others.sorted { abs($0.price - price) < abs($1.price - price) }
        default:
            ranked = others.filter { $0.category == category } + others.filter { $0.category != category }
        }
        return Array(ranked.prefix(max(0, count)))
    }
}
