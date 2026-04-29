//
//  YearlyVignetteSelectorView.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 27..
//

import SwiftUI

struct YearlyVignetteSelectorView: View {
    let viewModel: HighwayOverviewViewModel
    let onFinish: () -> Void

    @State private var countyMapData: HungaryCountyMapData?
    @State private var selectedCountyNames: Set<String> = []
    @State private var isShowingConnectivityAlert = false
    @State private var shouldNavigateToConfirmation = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Éves vármegyei matricák")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color(red: 0.05, green: 0.18, blue: 0.30))

                    countyMap

                    countyList

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fizetendő összeg")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(priceText(totalPrice))
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundStyle(Color(red: 0.05, green: 0.18, blue: 0.30))
                    }

                    Button {
                        handleContinue()
                    } label: {
                        Text("Tovább")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.03, green: 0.17, blue: 0.29))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationDestination(isPresented: $shouldNavigateToConfirmation) {
            PurchaseConfirmationView(
                viewModel: viewModel,
                vehicleInfo: viewModel.vehicleInfo,
                vignetteType: String(localized: "Éves vármegyei"),
                lineItems: confirmationLineItems,
                totalPrice: confirmationTotalPrice,
                requestBody: HighwayOrderRequest(
                    highwayOrders: selectedCountiesInDisplayOrder.map { county in
                        HighwayOrder(
                            type: county.id,
                            category: viewModel.vehicleInfo?.type ?? "CAR",
                            cost: countyPrice
                        )
                    }
                ),
                onFinish: onFinish
            )
        }
        .navigationTitle("E-matrica")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Nem összefüggő kijelölés", isPresented: $isShowingConnectivityAlert) {
            Button("Rendben", role: .cancel) {
            }
        }
        .task {
            if countyMapData == nil {
                countyMapData = try? await HungaryCountyMapStore.shared.loadMapDataIfNeeded()
            }
        }
    }

    private var countyMap: some View {
        Group {
            if let countyMapData {
                HungaryCountyMapView(mapData: countyMapData, selectedCountyIDs: selectedCountyIDs)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 220)
        .aspectRatio(1.45, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var countyList: some View {
        VStack(spacing: 0) {
            ForEach(counties.indices, id: \.self) { index in
                let county = counties[index]

                Button {
                    toggleCounty(county.name)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selectedCountyNames.contains(county.name) ? "checkmark.square.fill" : "square")
                            .font(.body)
                            .foregroundStyle(
                                selectedCountyNames.contains(county.name)
                                ? Color(.systemGray3)
                                : Color(.systemGray4)
                            )

                        Text(county.name)
                            .font(.subheadline)
                            .foregroundStyle(
                                selectedCountyNames.contains(county.name)
                                ? Color(.secondaryLabel)
                                : Color(red: 0.05, green: 0.18, blue: 0.30)
                            )

                        Spacer()

                        Text(priceText(countyPrice))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color(red: 0.05, green: 0.18, blue: 0.30))
                    }
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < counties.count - 1 {
                    Divider()
                        .padding(.leading, 26)
                }
            }
        }
    }

    private var counties: [County] {
        let liveCounties = (viewModel.highwayInfo?.payload.counties ?? [])
            .filter { $0.name != "Békés" }

        if !liveCounties.isEmpty {
            return liveCounties
        }

        return [
            County(id: "1", name: "Bács-Kiskun"),
            County(id: "2", name: "Baranya"),
            County(id: "3", name: "Borsod-Abaúj-Zemplén"),
            County(id: "4", name: "Csongrád"),
            County(id: "5", name: "Fejér"),
            County(id: "6", name: "Győr-Moson-Sopron"),
            County(id: "7", name: "Hajdú-Bihar"),
            County(id: "8", name: "Heves"),
            County(id: "9", name: "Komárom-Esztergom"),
            County(id: "10", name: "Pest"),
            County(id: "11", name: "Somogy"),
            County(id: "12", name: "Szabolcs-Szatmár-Bereg"),
            County(id: "13", name: "Tolna"),
            County(id: "14", name: "Vas"),
            County(id: "15", name: "Veszprém"),
            County(id: "16", name: "Zala"),
        ]
    }

    private var countyPrice: Double {
        5450
    }

    private var selectedCountyIDs: Set<String> {
        Set(selectedCountyNames.compactMap { Self.countyIDByName[$0] })
    }

    private var totalPrice: Double {
        Double(selectedCountyNames.count) * countyPrice
    }

    private var serviceFee: Double {
        110
    }

    private var confirmationLineItems: [PurchaseConfirmationView.LineItem] {
        let countyItems = selectedCountiesInDisplayOrder.map { county in
            PurchaseConfirmationView.LineItem(
                id: county.id,
                plainTitle: county.name,
                amount: countyPrice,
                emphasized: true
            )
        }

        return countyItems + [
            PurchaseConfirmationView.LineItem(
                id: "fee",
                localizedTitle: "Rendszerhasználati díj",
                amount: serviceFee,
                emphasized: false
            )
        ]
    }

    private var confirmationTotalPrice: Double {
        totalPrice + serviceFee
    }

    private var selectedCountiesInDisplayOrder: [County] {
        counties.filter { selectedCountyNames.contains($0.name) }
    }

    private func toggleCounty(_ countyName: String) {
        if selectedCountyNames.contains(countyName) {
            selectedCountyNames.remove(countyName)
        } else {
            selectedCountyNames.insert(countyName)
        }
    }

    private func handleContinue() {
        guard countyMapData != nil else {
            return
        }

        let disconnectedCountyNames = disconnectedSelectedCountyNames()

        guard selectedCountyNames.isEmpty == false else {
            return
        }

        guard disconnectedCountyNames.isEmpty else {
            isShowingConnectivityAlert = true
            return
        }

        shouldNavigateToConfirmation = true
    }

    private func disconnectedSelectedCountyNames() -> [String] {
        guard let adjacencyGraph = countyMapData?.adjacencyGraph else {
            return []
        }

        let selectedIDs = selectedCountyIDs

        guard selectedIDs.count > 1, let startID = selectedIDs.first else {
            return []
        }

        var visited: Set<String> = []
        var queue: [String] = [startID]

        while let currentID = queue.first {
            queue.removeFirst()

            guard !visited.contains(currentID) else {
                continue
            }

            visited.insert(currentID)

            for neighbor in adjacencyGraph[currentID, default: []] where selectedIDs.contains(neighbor) {
                if !visited.contains(neighbor) {
                    queue.append(neighbor)
                }
            }
        }

        return selectedIDs
            .subtracting(visited)
            .compactMap { Self.countyNameByID[$0] }
            .sorted()
    }

    private func priceText(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0

        let amount = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(amount) Ft"
    }

    private static let countyIDByName: [String: String] = [
        "Bács-Kiskun": "bk",
        "Baranya": "baranya",
        "Borsod-Abaúj-Zemplén": "baz",
        "Budapest": "budapest",
        "Csongrád": "csongrad",
        "Fejér": "fejer",
        "Győr-Moson-Sopron": "gyms",
        "Hajdú-Bihar": "hb",
        "Heves": "heves",
        "Jász-Nagykun-Szolnok": "jnsz",
        "Komárom-Esztergom": "ke",
        "Nógrád": "nograd",
        "Pest": "pest",
        "Somogy": "somogy",
        "Szabolcs-Szatmár-Bereg": "szszb",
        "Tolna": "tolna",
        "Vas": "vas",
        "Veszprém": "veszprem",
        "Zala": "zala",
    ]

    private static let countyNameByID: [String: String] = Dictionary(
        uniqueKeysWithValues: countyIDByName.map { ($1, $0) }
    )
}

#Preview {
    YearlyVignetteSelectorView(
        viewModel: HighwayOverviewViewModel(
            apiClient: HighwayAPIClient(baseURL: URL(string: "http://0.0.0.0:8080")!)
        ),
        onFinish: {}
    )
}
