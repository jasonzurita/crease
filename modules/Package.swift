// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Crease",
    platforms: [.iOS("26")],
    products: [
        .library(name: "CRApp", targets: ["CRApp"]),
        .library(name: "CRModel", targets: ["CRModel"]),
        .library(name: "CRDesign", targets: ["CRDesign"]),
        .library(name: "CRWorld", targets: ["CRWorld"]),
        .library(name: "RotationSolver", targets: ["RotationSolver"]),
        .library(name: "ApplicationClient", targets: ["ApplicationClient"]),
        .library(name: "FileManagerClient", targets: ["FileManagerClient"]),
        .library(name: "UserDefaultsClient", targets: ["UserDefaultsClient"]),
        .library(name: "CodablePersistenceClient", targets: ["CodablePersistenceClient"]),
    ],
    targets: [
        // MARK: - App

        .target(
            name: "CRApp",
            dependencies: [
                "CRModel",
                "CRDesign",
                "CRWorld",
                "RotationSolver",
                "CodablePersistenceClient",
                "FileManagerClient",
                "UserDefaultsClient",
            ],
            path: "Modules/App/src"
        ),
        .testTarget(
            name: "CRAppTests",
            dependencies: [
                "CRApp",
                "CRModel",
                "FileManagerClient",
                "UserDefaultsClient",
            ],
            path: "Modules/App/Tests"
        ),

        // MARK: - Model

        .target(
            name: "CRModel",
            path: "Modules/Model/src"
        ),
        .testTarget(
            name: "CRModelTests",
            dependencies: ["CRModel"],
            path: "Modules/Model/Tests"
        ),

        // MARK: - Design

        .target(
            name: "CRDesign",
            dependencies: ["CRModel"],
            path: "Modules/Design/src"
        ),

        // MARK: - World

        .target(
            name: "CRWorld",
            dependencies: [
                "ApplicationClient",
                "FileManagerClient",
                "UserDefaultsClient",
            ],
            path: "Modules/World/src"
        ),

        // MARK: - RotationSolver

        .target(
            name: "RotationSolver",
            dependencies: ["CRModel"],
            path: "Modules/RotationSolver/src"
        ),
        .testTarget(
            name: "RotationSolverTests",
            dependencies: ["RotationSolver", "CRModel"],
            path: "Modules/RotationSolver/Tests"
        ),

        // MARK: - BasicClients

        .target(
            name: "ApplicationClient",
            path: "Modules/BasicClients/ApplicationClient/src"
        ),
        .target(
            name: "FileManagerClient",
            path: "Modules/BasicClients/FileManagerClient/src"
        ),
        .target(
            name: "UserDefaultsClient",
            path: "Modules/BasicClients/UserDefaultsClient/src"
        ),
        .target(
            name: "CodablePersistenceClient",
            dependencies: ["FileManagerClient"],
            path: "Modules/BasicClients/CodablePersistenceClient/src"
        ),
        .testTarget(
            name: "CodablePersistenceClientTests",
            dependencies: ["CodablePersistenceClient"],
            path: "Modules/BasicClients/CodablePersistenceClient/Tests"
        ),

        // MARK: - Features

        // Add feature targets here as they are built (one per phase).
    ]
)
