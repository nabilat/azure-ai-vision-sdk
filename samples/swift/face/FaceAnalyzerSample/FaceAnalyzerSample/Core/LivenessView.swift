//
// Copyright (c) Microsoft. All rights reserved.
//

import Foundation
import SwiftUI
import AVFoundation
import AzureAIVisionFace

struct LivenessView: View {

    @State private var actor: LivenessActor? = nil
    // localization can be applied to feedbackMessage
    @State private var feedbackMessage: String = "Hold still."
    @State private var resultMessage: String = ""
    @State private var resultId: String = ""
    @State private var backgroundColor: Color? = Color.white
    var logHandler: (() -> Void) = {}

    // required token to initialize and authorize the client, you may consider to create token in your backend directly
    let token: String
    // boolean indicates whether liveness detection is run with verification or not
    let withVerification: Bool
    // optional reference image provided in client side, you may consider to provide reference image in your backend directly
    let referenceImage: UIImage?
    // the completion handler used to handle detection results and help on UI switch
    let completionHandler: (String, String) -> Void
    // the details handler to get the digest, which can be used to validate the integrity of the transport
    let detailsHandler: (FaceAnalyzedDetails?) -> Void

    init(token: String,
         withVerification: Bool = false,
         referenceImage: UIImage? = nil,
         completionHandler: @escaping (String, String)->Void = {_,_ in },
         detailsHandler: @escaping (FaceAnalyzedDetails?)->Void = {_ in }) {
        self.token = token
        self.withVerification = withVerification
        self.referenceImage = referenceImage
        self.completionHandler = completionHandler
        self.detailsHandler = detailsHandler
    }

    var body: some View {
        ZStack(alignment: .center) {
            CameraView(
                backgroundColor: $backgroundColor,
                feedbackMessage: $feedbackMessage) { visionSource in
                    let actor = self.actor ?? LivenessActor.init(
                        userFeedbackHandler: { feedback in
                            self.feedbackMessage = feedback
                        },
                        resultHandler: {result, resultId in
                            // This is just for demo purpose
                            // You should handle the liveness result in your own way
                            self.feedbackMessage = result
                            self.resultMessage = result
                            self.resultId = resultId
                            self.actionDidComplete()
                        },
                        screenBackgroundColorHandler: { color in
                            self.backgroundColor = color
                        },
                        detailsHandler: { faceAnalyzedDetails in
                            // Not necessary, but you can get the digest details here
                            self.detailsHandler(faceAnalyzedDetails)
                        },
                        logHandler: {
                            self.logHandler()
                        },
                        withVerification: self.withVerification,
                        referenceImage: self.referenceImage)
                    self.actor = actor
                    Task {
                        await actor.start(usingSource: visionSource, token: self.token)
                    }
                }
        }
    }

    func actionDidComplete() {
        self.actor?.stopAnalyzer()
        self.completionHandler(resultMessage, resultId)
    }

}

