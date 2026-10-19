# Navigation and search

[Archive home](README.md)

1. Start with the handoff guide or a conversation README.
2. Follow numbered parts for unique messages. Use MESSAGE_INDEX.md to reconstruct the complete included sequence, including shared prefixes and alternate branches.
3. Find an exact reference such as `C037-M00639` in Indexes/Message_Index.csv. Its `read_path` resolves to the full body and a stable anchor.
4. For a local styled reading experience, open Reader/index.html. No server, account or internet connection is required for the text reader. Historical external links still require their original destination.
5. Search all downloaded Markdown with your editor, or use `rg 'matched source-field' Conversations`. Search JSONL when exact record-level fields matter.

## Message references

`C037-M00639` means conversation C037, source node sequence 639. These are archive references, not invented platform message IDs. The machine-readable files also retain the original message and parent-node IDs. Gaps are expected: internal reasoning records do not appear in the public transcript.

Every source reference used by the case study has an exact anchor. Source sequence order is retained even when an export includes an alternate response. The `active_path` column distinguishes the exported selected path from alternatives.

## Branches

Full bodies inherited by several branches are stored once in Markdown and linked from each branch's message index. JSONL retains the complete text for each included occurrence, so a branch can also be read or analyzed without resolving the Markdown links. Counts distinguish unique bodies from occurrences.

## Historical links

Sandbox download links and ChatGPT citation tokens belong to the original conversation. They are preserved as historical text and are not promised to resolve publicly. Use the repository's accepted artifacts for code and QA results, or the attachment inventory for a transcript attachment's availability.
