# Format, coverage and provenance

[Archive home](README.md)

## Scope

The supplied export contains 166 conversations through October 17, 2026. It was scanned for CDS identifiers, project titles, repository names and campaign run identifiers. Dedicated CDS threads and supporting execution/visual/reporting chats receive full visible-text coverage. Mixed-purpose conversations receive complete matching turns and responses; C032's project genesis (source sequences 660–673) and C051's CDS publication phase (through 319) plus its Power BI planning segment (1241–1280) are included as contiguous ranges.

See Indexes/Corpus_Scope.csv for the disposition of every source conversation, and Indexes/Conversation_Index.csv for exact included/available counts. A match in another project's discussion is included as context, not relabeled as a CDS build. Unrelated private chats are outside the publication scope.

## Included content

- 16 full project conversations; 34 mixed conversations with scoped related exchanges.
- 11,573 visible occurrences; 3,250 unique full bodies.
- User and assistant text/multimodal-text records, active and alternative branches, original timestamps and parent links.
- 2,688 attachment metadata records. Most attachment/image bytes are not present in this derivative.
- One recovered attached prompt: C038-M00176 / Pasted text(101).txt. Its exported text body is empty; the recovered file is separate and explicitly linked.

Internal reasoning and recap records are not published. No missing response, image description or attachment body was invented. “Full” is bounded by the actual visible text supplied in this export; it does not imply access to later chats or missing file bytes.

## Text fidelity

Each JSONL record includes the original text SHA-256 and public text SHA-256. Public text preserves original wording except for deterministic email, telephone, local-user-directory and credential removal. Redaction markers stay visible and a category/count ledger identifies every affected canonical message. These edits do not change the presentation's quoted text. Markdown source bodies are delimited by BEGIN_MESSAGE / END_MESSAGE comments. HTML is a reading view rendered from the same public text with raw HTML disabled.

Markdown adds speaker labels, chronology, attachment notes and navigation outside message bodies. The HTML reader uses black human prompts and white assistant responses. It is a view of the exported text, not an additional source.

## Sources and branch handling

Provenance/Source_Exports.json records the original export filenames, sizes and SHA-256 values. The JSON and chat.html export were previously reconciled as the same conversation objects; this archive is built from the canonical messages and occurrence mapping derived from those JSON exports.

Identical inherited records use one canonical readable body. Every occurrence retains its conversation ID, node sequence and branch state in Indexes/Message_Index.csv. Public JSONL carries full text per occurrence for simple downstream ingestion. This prevents branch repetition from inflating unique-message claims.

## Dates and authority

Timestamps preserve the export's America/New_York offset. Unknown values remain unknown. The source cutoff is the supplied October 17 export; the archive assembly date is October 19, 2026. Conversation proposals, historical verdicts and rejected code remain history. Retained source and QA artifacts govern final system behavior.
