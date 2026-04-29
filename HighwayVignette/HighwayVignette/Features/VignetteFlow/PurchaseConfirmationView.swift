//
//  PurchaseConfirmationView.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 27..
//

import SwiftUI

struct PurchaseConfirmationView: View {
    let viewModel: HighwayViewModel
    let vehicleInfo: VehicleInfoResponse?
    let vignetteType: String
    let lineItems: [LineItem]
    let totalPrice: Double
    let requestBody: HighwayOrderRequest
    let onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false
    @State private var isShowingErrorAlert = false
    @State private var errorAlertTitle = ""
    @State private var shouldNavigateToSuccess = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Vásárlás megerősítése")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color(red: 0.05, green: 0.18, blue: 0.30))

                        detailRow("Rendszám", formattedPlate(vehicleInfo?.plate))
                        detailRow("Matrica típusa", vignetteType)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(lineItems) { item in
                            priceRow(item)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fizetendő összeg")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color(red: 0.05, green: 0.18, blue: 0.30))

                        Text(priceText(totalPrice))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(Color(red: 0.05, green: 0.18, blue: 0.30))
                    }

                    VStack(spacing: 18) {
                        Button {
                            submitOrder()
                        } label: {
                            Group {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Tovább")
                                        .font(.headline.weight(.semibold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.03, green: 0.17, blue: 0.29))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isSubmitting || lineItems.isEmpty)

                        Button {
                            dismiss()
                        } label: {
                            Text("Mégsem")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color(red: 0.03, green: 0.17, blue: 0.29))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .overlay(
                                    Capsule()
                                        .stroke(Color(red: 0.03, green: 0.17, blue: 0.29), lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationDestination(isPresented: $shouldNavigateToSuccess) {
            VignettePurchaseSuccessView(onFinish: onFinish)
        }
        .navigationTitle("E-matrica")
        .navigationBarTitleDisplayMode(.inline)
        .alert(errorAlertTitle, isPresented: $isShowingErrorAlert) {
            Button("Rendben", role: .cancel) {
            }
        }
    }

    private func detailRow(_ title: LocalizedStringResource, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.body)
                .foregroundStyle(Color(red: 0.28, green: 0.38, blue: 0.49))

            Spacer(minLength: 16)

            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(Color(red: 0.28, green: 0.38, blue: 0.49))
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private func priceTitle(_ item: LineItem) -> some View {
        switch item.title {
        case .localized(let title):
            Text(title)
        case .plain(let title):
            Text(title)
        }
    }

    private func priceRow(_ item: LineItem) -> some View {
        HStack(alignment: .top) {
            priceTitle(item)
                .font(item.emphasized ? .title3.weight(.bold) : .headline.weight(.semibold))
                .foregroundStyle(
                    item.emphasized
                    ? Color(red: 0.05, green: 0.18, blue: 0.30)
                    : Color(red: 0.28, green: 0.38, blue: 0.49)
                )

            Spacer(minLength: 16)

            Text(priceText(item.amount))
                .font(.title3.weight(.medium))
                .foregroundStyle(Color(red: 0.28, green: 0.38, blue: 0.49))
        }
    }

    private func priceText(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0

        let amount = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(amount) Ft"
    }

    private func formattedPlate(_ plate: String?) -> String {
        guard let plate else {
            return "-"
        }

        return plate.replacingOccurrences(of: "-", with: " ").uppercased()
    }

    private func submitOrder() {
        guard !isSubmitting, lineItems.isEmpty == false else {
            return
        }

        isSubmitting = true

        Task {
            do {
                _ = try await viewModel.submitOrder(requestBody)
                shouldNavigateToSuccess = true
            } catch {
                errorAlertTitle = error.localizedDescription
                isShowingErrorAlert = true
            }

            isSubmitting = false
        }
    }
}

extension PurchaseConfirmationView {
    struct LineItem: Identifiable {
        enum Title {
            case localized(LocalizedStringResource)
            case plain(String)
        }

        let id: String
        let title: Title
        let amount: Double
        let emphasized: Bool

        init(
            id: String,
            localizedTitle: LocalizedStringResource,
            amount: Double,
            emphasized: Bool
        ) {
            self.id = id
            self.title = .localized(localizedTitle)
            self.amount = amount
            self.emphasized = emphasized
        }

        init(
            id: String,
            plainTitle: String,
            amount: Double,
            emphasized: Bool
        ) {
            self.id = id
            self.title = .plain(plainTitle)
            self.amount = amount
            self.emphasized = emphasized
        }
    }
}

#Preview("National") {
    PurchaseConfirmationView(
        viewModel: HighwayViewModel(
            apiClient: HighwayAPIClient(baseURL: URL(string: "http://0.0.0.0:8080")!)
        ),
        vehicleInfo: VehicleInfoResponse(
            statusCode: "OK",
            internationalRegistrationCode: "H",
            type: "CAR",
            name: "Michael Scott",
            plate: "ABC-123",
            country: LocalizedText(hu: "Magyarország", en: "Hungary"),
            vignetteType: "D1"
        ),
        vignetteType: "D1 - heti (10 napos)",
        lineItems: [
            .init(id: "vignette", localizedTitle: "Matrica díja", amount: 6200, emphasized: true),
            .init(id: "fee", localizedTitle: "Rendszerhasználati díj", amount: 200, emphasized: false),
        ],
        totalPrice: 6400,
        requestBody: HighwayOrderRequest(highwayOrders: []),
        onFinish: {}
    )
}

#Preview("Yearly County") {
    PurchaseConfirmationView(
        viewModel: HighwayViewModel(
            apiClient: HighwayAPIClient(baseURL: URL(string: "http://0.0.0.0:8080")!)
        ),
        vehicleInfo: VehicleInfoResponse(
            statusCode: "OK",
            internationalRegistrationCode: "H",
            type: "CAR",
            name: "Michael Scott",
            plate: "ABC-123",
            country: LocalizedText(hu: "Magyarország", en: "Hungary"),
            vignetteType: "D1"
        ),
        vignetteType: String(localized: "Éves vármegyei"),
        lineItems: [
            .init(id: "baranya", plainTitle: "Baranya", amount: 5450, emphasized: true),
            .init(id: "fejer", plainTitle: "Fejér", amount: 5450, emphasized: true),
            .init(id: "fee", localizedTitle: "Rendszerhasználati díj", amount: 110, emphasized: false),
        ],
        totalPrice: 11010,
        requestBody: HighwayOrderRequest(highwayOrders: []),
        onFinish: {}
    )
}
