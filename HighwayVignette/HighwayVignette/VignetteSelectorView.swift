//
//  VignetteSelectorView.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 24..
//

import SwiftUI

struct VignetteSelectorView: View {
    @State private var viewModel: HighwayOverviewViewModel
    @State private var selectedVignetteID: String?
    @State private var shouldNavigateToVignetteConfirmation = false
    @State private var shouldNavigateToYearlySelector = false

    init(apiClient: HighwayAPIClient) {
        _viewModel = State(initialValue: HighwayOverviewViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                Group {
                    switch viewModel.state {
                    case .idle, .loading:
                        loadingView
                    case .failed:
                        failureView
                    case .loaded:
                        loadedView
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("E-matrica")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.load()
            selectDefaultVignetteIfNeeded()
        }
        .onChange(of: viewModel.highwayInfo?.payload.highwayVignettes.count) { _, _ in
            selectDefaultVignetteIfNeeded()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Adatok betöltése...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                vehicleCard
                countryVignettesCard
                countyVignettesCard
            }
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
    }

    private var vehicleCard: some View {
        Group {
            if let vehicleInfo = viewModel.vehicleInfo {
                HStack(spacing: 14) {
                    Image(systemName: "car.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedPlate(vehicleInfo.plate))
                            .font(.headline)
                        Text(vehicleInfo.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(18)
                .background(cardBackground)
            }
        }
    }

    private var countryVignettesCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Országos matricák")
                .font(.title3.weight(.semibold))

            VStack(spacing: 10) {
                ForEach(vignetteRows) { row in
                    vignetteRow(row)
                }
            }

            Button {
                shouldNavigateToVignetteConfirmation = true
            } label: {
                Text("Vásárlás")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.03, green: 0.17, blue: 0.29))
                    )
            }
            .buttonStyle(.plain)
            .opacity(selectedVignette == nil ? 0.5 : 1)
            .disabled(selectedVignette == nil)
        }
        .padding(18)
        .background(cardBackground)
        .navigationDestination(isPresented: $shouldNavigateToVignetteConfirmation) {
            if let selectedVignette {
                PurchaseConfirmationView(
                    viewModel: viewModel,
                    vehicleInfo: viewModel.vehicleInfo,
                    vignetteType: selectedVignetteTitle,
                    lineItems: [
                        .init(
                            id: "vignette",
                            localizedTitle: "Matrica díja",
                            amount: selectedVignette.cost,
                            emphasized: true
                        ),
                        .init(
                            id: "fee",
                            localizedTitle: "Rendszerhasználati díj",
                            amount: selectedVignette.trxFee,
                            emphasized: false
                        ),
                    ],
                    totalPrice: selectedVignette.sum,
                    requestBody: HighwayOrderRequest(
                        highwayOrders: [
                            HighwayOrder(
                                type: selectedVignette.vignetteType.first ?? "",
                                category: viewModel.vehicleInfo?.type ?? selectedVignette.vehicleCategory,
                                cost: selectedVignette.cost
                            )
                        ]
                    ),
                    onFinish: { shouldNavigateToVignetteConfirmation = false }
                )
            }
        }
    }

    private var countyVignettesCard: some View {
        Button {
            shouldNavigateToYearlySelector = true
        } label: {
            HStack {
                Text("Éves vármegyei matricák")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $shouldNavigateToYearlySelector) {
            YearlyVignetteSelectorView(
                viewModel: viewModel,
                onFinish: { shouldNavigateToYearlySelector = false }
            )
        }
    }

    private func vignetteRow(_ row: VignetteRow) -> some View {
        Button {
            selectedVignetteID = row.id
        } label: {
            HStack(spacing: 14) {
                Image(systemName: row.id == selectedVignetteID ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(row.id == selectedVignetteID ? Color.accentColor : Color(.systemGray3))

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 12)

                Text(priceText(for: row.option.sum))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        row.id == selectedVignetteID ? Color.accentColor : Color(.separator).opacity(0.2),
                        lineWidth: row.id == selectedVignetteID ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var failureView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nem sikerült betölteni az adatokat")
                .font(.headline)
            Text(viewModel.errorMessage ?? "Ismeretlen hiba")
                .foregroundStyle(.secondary)
            Button("Újra") {
                Task {
                    await viewModel.load()
                    selectDefaultVignetteIfNeeded()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var vignetteRows: [VignetteRow] {
        guard let highwayInfo = viewModel.highwayInfo else {
            return []
        }

        let sortOrder = ["WEEK": 0, "MONTH": 1, "DAY": 2]

        return highwayInfo.payload.highwayVignettes.enumerated().compactMap { index, option in
            guard
                let type = option.vignetteType.first?.uppercased(),
                let order = sortOrder[type]
            else {
                return nil
            }

            return VignetteRow(
                id: "\(option.vehicleCategory)-\(option.vignetteType.joined(separator: "-"))-\(index)",
                option: option,
                sortOrder: order
            )
        }
        .sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.id < rhs.id
            }

            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private var selectedVignette: HighwayVignetteOption? {
        vignetteRows.first(where: { $0.id == selectedVignetteID })?.option
    }

    private var selectedVignetteTitle: String {
        guard let row = vignetteRows.first(where: { $0.id == selectedVignetteID }) else {
            return ""
        }

        return row.title
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(.systemBackground))
    }

    private func selectDefaultVignetteIfNeeded() {
        guard selectedVignetteID == nil, let first = vignetteRows.first else {
            return
        }

        selectedVignetteID = first.id
    }

    private func formattedPlate(_ plate: String) -> String {
        plate.replacingOccurrences(of: "-", with: " ").uppercased()
    }

    private func priceText(for value: Double) -> String {
        "\(Int(value)) Ft"
    }
}

private struct VignetteRow: Identifiable {
    let id: String
    let option: HighwayVignetteOption
    let sortOrder: Int

    var title: String {
        let type = option.vignetteType.joined(separator: ", ")
        return "D1 - \(displayName(for: type))"
    }

    private func displayName(for type: String) -> String {
        switch type.uppercased() {
        case "DAY":
            return String(localized: "napi (1 napos)")
        case "WEEK":
            return String(localized: "heti (10 napos)")
        case "MONTH":
            return String(localized: "havi")
        case "YEAR":
            return String(localized: "éves")
        default:
            return type.lowercased()
        }
    }
}

#Preview {
    VignetteSelectorView(
        apiClient: HighwayAPIClient(baseURL: URL(string: "http://0.0.0.0:8080")!)
    )
}
