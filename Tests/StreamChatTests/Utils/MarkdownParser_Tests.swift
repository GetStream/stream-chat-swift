//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

// Note: Snapshot tests are in ChatMessageMarkdown_Tests

@available(iOS 15, *)
final class MarkdownParser_Tests: XCTestCase {
    private var parser: MarkdownParser!
    
    override func setUpWithError() throws {
        parser = MarkdownParser()
    }
    
    override func tearDownWithError() throws {
        parser = nil
    }
    
    func test_style_text() throws {
        let text = "This is some text"
        var didStyle = false
        let result = try parser.style(
            markdown: text,
            options: MarkdownParser.ParsingOptions(),
            attributes: AttributeContainer(),
            inlinePresentationIntentAttributes: { _ in
                didStyle = true
                return nil
            },
            presentationIntentAttributes: { _, _ in
                didStyle = true
                return nil
            }
        )
        XCTAssertEqual(false, didStyle)
        XCTAssertEqual(text, String(result.characters))
    }
    
    func test_style_textWithNewlines() throws {
        let text = """
        This is the first line
        
        
        This is the fourth line
        """
        var didStyle = false
        let result = try parser.style(
            markdown: text,
            options: MarkdownParser.ParsingOptions(),
            attributes: AttributeContainer(),
            inlinePresentationIntentAttributes: { _ in
                didStyle = true
                return nil
            },
            presentationIntentAttributes: { _, _ in
                didStyle = true
                return nil
            }
        )
        XCTAssertEqual(false, didStyle)
        XCTAssertEqual(text, String(result.characters))
    }
    
    func test_style_detectPresentationIntents() throws {
        let markdown = """
        # H1  
        - Unordered 1
        - Unordered 2
            - Unordered _nested_
        
        ## H2  
        1. Ordered **1**
        2. Ordered 2
            1. Ordered nested
        
        Text
        
        ### H3  
        > Text that is a quote
        
        #### H4  
        ```swift
        Code block
        ```
        ##### H5
        ###### H6
        """
        let expectedPresentationKinds = Set<PresentationIntent.Kind>([
            .blockQuote,
            .codeBlock(languageHint: "swift"),
            .header(level: 1),
            .header(level: 2),
            .header(level: 3),
            .header(level: 4),
            .header(level: 5),
            .header(level: 6),
            .listItem(ordinal: 1),
            .listItem(ordinal: 2)
        ])
        let expectedInlinePresentationIntents = Set<InlinePresentationIntent>([
            .emphasized, .stronglyEmphasized
        ])
        var parsedPresentationKinds = Set<PresentationIntent.Kind>()
        var parsedInlinePresentationKinds = Set<InlinePresentationIntent>()
        _ = try parser.style(
            markdown: markdown,
            options: .init(layoutDirectionLeftToRight: true),
            attributes: AttributeContainer(),
            inlinePresentationIntentAttributes: { intent in
                parsedInlinePresentationKinds.insert(intent)
                return nil
            },
            presentationIntentAttributes: { kind, _ in
                parsedPresentationKinds.insert(kind)
                return nil
            }
        )
        XCTAssertEqual(expectedInlinePresentationIntents, parsedInlinePresentationKinds)
        XCTAssertEqual(expectedPresentationKinds, parsedPresentationKinds)
    }
    
    func test_style_fixLinksWithoutSchemeAndHost() throws {
        let markdown = """
        [link](getstream.io)
        [link](https://example.com)
        [link](https://getstream.io/chat/)
        """
        let string = try MarkdownParser().style(
            markdown: markdown,
            options: MarkdownParser.ParsingOptions(),
            attributes: AttributeContainer(),
            inlinePresentationIntentAttributes: { _ in nil },
            presentationIntentAttributes: { _, _ in nil }
        )
        let expected = [
            "https://getstream.io",
            "https://example.com",
            "https://getstream.io/chat/"
        ]
        let result = string.runs[\.link].compactMap { $0.0?.absoluteString }
        XCTAssertEqual(expected, result)
    }
    
    func test_style_doesNotCrashWithLongMarkdownContainingManyPresentationIntents() throws {
        let text = """
        How it works for the company
        1. The company signs up with Lease a Bike

        The employer registers on the Lease a Bike platform and defines the internal policy:

        who is eligible
        max bike budget (if any)
        whether the company contributes financially
        what happens if someone leaves early
        whether commuting allowance changes
        Typical setup time:
        2. Employer chooses cost model

        Most Dutch companies use one of these models:

        Option A — Cost-neutral for employer (most common)
        Because gross salary decreases:

        employer pays less social security contributions
        employee gets tax benefit

        Lease a Bike claims employers save roughly €20–€25/month per leased bike in payroll taxes.
        employer can offer the program with almost no extra cost
        sometimes even slightly positive financially
        Option B — Employer contributes
        e.g. €25–€50/month contribution
        often positioned as a mobility/wellness benefit

        Very common in tech and corporate environments.

        3. Employer approves employee requests
        manager/HR gets approval request
        one-click approval in the platform
        Lease a Bike handles dealer + leasing admin

        The employer mainly handles:

        payroll deduction
        monthly invoice
        HR policy compliance
        4. Monthly payroll administration

        Every month:

        employer receives invoice from Lease a Bike
        payroll deducts agreed gross amount from employee salary
        5. If employee leaves the company

        employer settles remaining contract with leasing company
        employee reimburses employer
        affiliated bike shops
        Lease a Bike dealer network
        There are hundreds of brands available.
        The agreement defines:
        duration (usually 36 months)
        insurance
        maintenance
        theft coverage
        3. Employee receives tax advantage
        Instead of paying from net salary:
        employee pays less income tax
        effective bike cost becomes much lower
        sometimes more if employer contributes
        4. Employee pays small "bijtelling"
        €3,000 e-bike
        taxable addition = €210/year
        unlimited private use allowed
        no minimum commuting requirement anymore
        theft insurance
        damage coverage
        maintenance budget
        roadside assistance
        bike price = €3,500
        lease term = 36 months
        maintenance + insurance included
        employer contributes €30/month
        much cheaper than buying privately upfront
        no large initial payment
        services included
        Why companies offer it
        supports sustainability goals
        promotes healthier commuting
        helps employer branding
        can reduce commuting reimbursements and sick days
        For Amsterdam specifically, bike leasing has become almost a standard white-collar benefit now.

        """
        let result = try parser.style(
            markdown: text,
            options: MarkdownParser.ParsingOptions(),
            attributes: AttributeContainer(),
            inlinePresentationIntentAttributes: { _ in nil },
            presentationIntentAttributes: { _, _ in nil }
        )
        let hasLeftoverPresentationIntent = result.runs[\.presentationIntent].contains { intent, _ in intent != nil }
        XCTAssertFalse(hasLeftoverPresentationIntent, "MarkdownParser must clear NSPresentationIntent on the parsed output")
    }
}
