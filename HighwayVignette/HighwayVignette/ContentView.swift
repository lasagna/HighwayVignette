//
//  ContentView.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 24..
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel: HighwayOverviewViewModel

    init(apiClient: HighwayAPIClient) {
        _viewModel = State(initialValue: HighwayOverviewViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading highway data...")
                case .failed:
                    failureView
                case .loaded:
                    loadedView
                }
            }
            .padding()
            .navigationTitle("Highway Vignette")
        }
        .task {
            await viewModel.load()
        }
    }

    private var loadedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let vehicleInfo = viewModel.vehicleInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vehicle")
                        .font(.headline)
                    Text(vehicleInfo.name)
                    Text(vehicleInfo.plate.uppercased())
                    Text(vehicleInfo.country.en)
                        .foregroundStyle(.secondary)
                }
            }

            if let highwayInfo = viewModel.highwayInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Vignettes")
                        .font(.headline)

                    ForEach(
                        Array(highwayInfo.payload.highwayVignettes.enumerated()),
                        id: \.offset
                    ) { _, vignette in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vignette.vehicleCategory)
                                .font(.subheadline.weight(.semibold))
                            Text(vignette.vignetteType.joined(separator: ", "))
                                .foregroundStyle(.secondary)
                            Text("Total: \(vignette.sum, format: .number.precision(.fractionLength(0)))")
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var failureView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Could not load data")
                .font(.headline)
            Text(viewModel.errorMessage ?? "Unknown error")
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task {
                    await viewModel.load()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView(
        apiClient: HighwayAPIClient(baseURL: URL(string: "http://0.0.0.0:8080")!)
    )
}
