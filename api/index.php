<?php

header('Content-Type: application/json');

$random = function() {
    $randomNumber = rand(10000000, 100000000);
    while ($randomNumber % 3 !== 0) {
        $randomNumber = rand(10000000, 100000000);
    }
    return $randomNumber;
};

switch (true) {
    case $_SERVER['REQUEST_METHOD'] === 'GET' && $_SERVER['REQUEST_URI'] === '/v1/highway/info':

        $response = [
            "requestId" => $random(),
            "statusCode" => "OK",
            "payload" => [
                "highwayVignettes" => [
                    [
                        "vignetteType" => ["DAY"],
                        "vehicleCategory" => "CAR",
                        "cost" => 5150.0,
                        "trxFee" => 200.0,
                        "sum" => 5350.0
                    ],
                    [
                        "vignetteType" => ["MONTH"],
                        "vehicleCategory" => "CAR",
                        "cost" => 10360.0,
                        "trxFee" => 200.0,
                        "sum" => 10560.0
                    ],
                    [
                        "vignetteType" => ["WEEK"],
                        "vehicleCategory" => "CAR",
                        "cost" => 6400.0,
                        "trxFee" => 200.0,
                        "sum" => 6600.0
                    ],
                    [
                        "vignetteType" => ["YEAR"],
                        "vehicleCategory" => "CAR",
                        "cost" => 6660.0,
                        "trxFee" => 200.0,
                        "sum" => 6860.0
                    ],
                    [
                        "vignetteType" => [
                            "YEAR_11", "YEAR_12", "YEAR_13", "YEAR_14", "YEAR_15", "YEAR_16", 
                            "YEAR_17", "YEAR_18", "YEAR_19", "YEAR_20", "YEAR_21", "YEAR_22", 
                            "YEAR_23", "YEAR_24", "YEAR_25", "YEAR_26", "YEAR_27", "YEAR_28", 
                            "YEAR_29"
                        ],
                        "vehicleCategory" => "CAR",
                        "cost" => 6660.0,
                        "trxFee" => 200.0,
                        "sum" => 6860.0
                    ]
                ],
                "vehicleCategories" => [
                    [
                        "category" => "CAR",
                        "vignetteCategory" => "D1",
                        "name" => [
                            "hu" => "Személygépjármű",
                            "en" => "Car"
                        ]
                    ]
                ],
                "counties" => [
                    [
                        "id" => "YEAR_11",
                        "name" => "Bács-Kiskun"
                    ],
                    [
                        "id" => "YEAR_12",
                        "name" => "Baranya"
                    ],
                    [
                        "id" => "YEAR_13",
                        "name" => "Békés"
                    ],
                    [
                        "id" => "YEAR_14",
                        "name" => "Borsod-Abaúj-Zemplén"
                    ],
                    [
                        "id" => "YEAR_15",
                        "name" => "Csongrád"
                    ],
                    [
                        "id" => "YEAR_16",
                        "name" => "Fejér"
                    ],
                    [
                        "id" => "YEAR_17",
                        "name" => "Győr-Moson-Sopron"
                    ],
                    [
                        "id" => "YEAR_18",
                        "name" => "Hajdú-Bihar"
                    ],
                    [
                        "id" => "YEAR_19",
                        "name" => "Heves"
                    ],
                    [
                        "id" => "YEAR_20",
                        "name" => "Jász-Nagykun-Szolnok"
                    ],
                    [
                        "id" => "YEAR_21",
                        "name" => "Komárom-Esztergom"
                    ],
                    [
                        "id" => "YEAR_22",
                        "name" => "Nógrád"
                    ],
                    [
                        "id" => "YEAR_23",
                        "name" => "Pest"
                    ],
                    [
                        "id" => "YEAR_24",
                        "name" => "Somogy"
                    ],
                    [
                        "id" => "YEAR_25",
                        "name" => "Szabolcs-Szatmár-Bereg"
                    ],
                    [
                        "id" => "YEAR_26",
                        "name" => "Tolna"
                    ],
                    [
                        "id" => "YEAR_27",
                        "name" => "Vas"
                    ],
                    [
                        "id" => "YEAR_28",
                        "name" => "Veszprém"
                    ],
                    [
                        "id" => "YEAR_29",
                        "name" => "Zala"
                    ]
                ]
            ],
            "dataType" => "HighwayTransaction"
        ];

        echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        break;
    case $_SERVER['REQUEST_METHOD'] === 'GET' && $_SERVER['REQUEST_URI'] === '/v1/highway/vehicle':
        $response = [
            "requestId" => $random(),
            "statusCode" => "OK",
            "internationalRegistrationCode" => "H",
            "type" => "CAR",
            "name" => "Michael Scott",
            "plate" => "abc-123",
            "country" => [
                "hu" => "Magyarország",
                "en" => "Hungary"
            ],
            "vignetteType" => "D1",
        ];

        echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        break;
    case $_SERVER['REQUEST_METHOD'] === 'POST' && $_SERVER['REQUEST_URI'] === '/v1/highway/order':
        $postData = file_get_contents("php://input");
        $data = json_decode($postData, true);

        if (isset($data['highwayOrders']) && is_array($data['highwayOrders'])) {
            $response = [
                "requestId" => $random(),
                "statusCode" => "OK",
                "receivedOrders" => $data['highwayOrders']
            ];
        } else {
            $response = [
                "requestId" => $random(),
                "statusCode" => "ERROR",
                "message" => "Invalid or missing highwayOrders parameter"
            ];
        }

        echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        break;
    default:
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
        break;
}
?>