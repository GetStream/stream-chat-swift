//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

// NOTE: Attachments tests used to freeze the test app on iOS > 18"
final class Attachments_Tests: StreamTestCase {
    func test_participantUploadsVideo() throws {
        linkToScenario(withId: 31)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant uploads a video") {
            participantRobot.uploadAttachment(type: .video)
        }
        THEN("user can see uploaded video") {
            userRobot.assertVideo(isPresent: true)
        }
    }
    
    func test_participantUploadsFile() throws {
        linkToScenario(withId: 33)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant uploads a file") {
            participantRobot.uploadAttachment(type: .file)
        }
        THEN("user can see uploaded file") {
            userRobot.assertFile(isPresent: true)
        }
    }

    func test_restartImageUpload() throws {
        linkToScenario(withId: 2195)

        GIVEN("user opens the channel") {
            userRobot
                .login()
                .openChannel()
        }
        WHEN("user sends an image beeing offline") {
            userRobot
                .setConnectivity(to: .off)
                .uploadImage()
        }
        AND("user restarts an image upload being online") {
            userRobot
                .setConnectivity(to: .on)
                .restartImageUpload()
        }
        THEN("user can see uploaded image") {
            userRobot.assertImage(isPresent: true)
        }
    }

    func test_uploadMultipleImages() {
        linkToScenario(withId: 11893)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user attaches multiple images") {
            userRobot.attachImages(count: 2)
        }
        THEN("images are displayed in preview") {
            userRobot.assertMediaAttachmentInPreview(isDisplayed: true, count: 2)
        }
        WHEN("user sends the images") {
            userRobot.tapOnSendButton()
        }
        THEN("user can see uploaded images") {
            userRobot.assertImages(isDisplayed: true, count: 2)
        }
    }

    func test_deleteImage() {
        linkToScenario(withId: 11894)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user attaches an image") {
            userRobot.attachImages()
        }
        AND("user sends the image") {
            userRobot
                .tapOnSendButton()
                .assertImages(isDisplayed: true)
        }
        AND("user deletes the image") {
            userRobot.deleteMessage()
        }
        THEN("user can see deleted message") {
            userRobot
                .assertImages(isDisplayed: false)
                .assertDeletedMessage()
        }
    }

    func test_uploadMultipleFiles() {
        linkToScenario(withId: 11896)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user attaches multiple files") {
            userRobot.attachFiles(count: 2)
        }
        THEN("files are displayed in preview") {
            userRobot.assertFileAttachmentInPreview(isDisplayed: true, count: 2)
        }
        WHEN("user sends the files") {
            userRobot.tapOnSendButton()
        }
        THEN("user can see uploaded files") {
            userRobot.assertFile(count: 2, isPresent: true)
        }
    }

    func test_deleteFile() {
        linkToScenario(withId: 11897)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("user attaches a file") {
            userRobot.attachFiles()
        }
        AND("user sends the file") {
            userRobot
                .tapOnSendButton()
                .assertFile(isPresent: true)
        }
        AND("user deletes the file") {
            userRobot.deleteMessage()
        }
        THEN("user can see deleted message") {
            userRobot
                .assertFile(count: 0, isPresent: false)
                .assertDeletedMessage()
        }
    }

    func test_imageUploadRecovers_whenUserComesBackOnline() throws {
        linkToScenario(withId: 11898)

        try XCTSkipIf(true, "Image upload that failed offline is not retried when the connection is back (no upload request is sent)")

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("user goes offline") {
            userRobot.setConnectivity(to: .off)
        }
        WHEN("user sends an image while offline") {
            userRobot
                .attachImages()
                .tapOnSendButton()
        }
        AND("user comes back online") {
            userRobot.setConnectivity(to: .on)
        }
        THEN("the image is uploaded") {
            userRobot.assertImages(isDisplayed: true)
        }
    }

    func test_participantUploadsMultipleImages() {
        linkToScenario(withId: 11899)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        WHEN("participant uploads multiple images") {
            participantRobot.uploadAttachment(type: .image, count: 2)
        }
        THEN("user can see the images in one message") {
            userRobot.assertImages(isDisplayed: true, count: 2)
        }
    }

    func test_userSwipesBetweenImagesInGallery() {
        linkToScenario(withId: 11900)

        GIVEN("user opens the channel") {
            userRobot.login().openChannel()
        }
        AND("participant uploads multiple images") {
            participantRobot.uploadAttachment(type: .image, count: 2)
        }
        WHEN("user opens the first image") {
            userRobot
                .assertImages(isDisplayed: true, count: 2)
                .openImageInGallery(imageIndex: 0)
        }
        THEN("the gallery shows the first image") {
            userRobot.assertGalleryPosition(1, of: 2)
        }
        WHEN("user swipes to the next image") {
            userRobot.swipeToNextImageInGallery()
        }
        THEN("the gallery shows the second image") {
            userRobot.assertGalleryPosition(2, of: 2)
        }
    }

    func test_restartImageUploadAfterRestartingTheApp() throws {
        linkToScenario(withId: 2723)

        GIVEN("user opens the channel") {
            userRobot
                .setIsLocalStorageEnabled(to: .on)
                .login()
                .openChannel()
        }
        WHEN("user sends an image being offline") {
            userRobot
                .setConnectivity(to: .off)
                .uploadImage()
                .assertImageUploadFailed()
        }
        AND("user restarts the app") {
            app.terminate()
            app.launch()
            userRobot
                .setIsLocalStorageEnabled(to: .on)
                .login()
                .openChannel()
        }
        AND("user restarts an image upload being online") {
            userRobot.restartImageUpload()
        }
        THEN("user can see uploaded image") {
            userRobot.assertImage(isPresent: true)
        }
    }

    func test_userUploadsVideo() throws {
        linkToScenario(withId: 30)

        GIVEN("user opens a channel") {
            userRobot.login().openChannel()
        }
        WHEN("user sends a video") {
            userRobot.uploadVideo()
        }
        THEN("user can see uploaded video") {
            userRobot.assertVideo(isPresent: true)
        }
    }
}
