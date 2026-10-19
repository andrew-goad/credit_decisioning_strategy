# MSBF - Power BI Executive Portfolio Intelligence Part 3

## Part 01

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md)

<a id="c118-m00227"></a>

### C118-M00227

**Andrew** · 2026-09-03T19:45:03.937000-04:00 · active path

<!-- BEGIN_MESSAGE C118-M00227 -->
I updated the model version, but I wonder if we shouldn't start targeting a more refined name in line with what we'll actually publish this as. We're not going to upload our first Power BI build to GitHub titled, MSBF_PBI_R26_PARALLEL.... Let's think of a publishable name and stick with that. It should be short and aligned to where we are in the build. This is through Module 2 architecture. It should also be a marketable name. Something we can share and it conveys professionalism and would be in line with something you'd present to a client.
<!-- END_MESSAGE C118-M00227 -->


---

<a id="c118-m00228"></a>

### C118-M00228

**ChatGPT** · 2026-09-03T19:45:06.864233-04:00 · active path

<!-- BEGIN_MESSAGE C118-M00228 -->
Yes. I would stop exposing the internal construction name once we finish this controlled build. `MSBF_PBI_R26_PARALLEL_REFINEMENT...` is useful lineage, but it reads like an engineering workstream—not a client-ready product.

My recommendation is:

# **MSBF Merchant Credit Intelligence**

Short form:

**MSBF MCI**

And I would use the subtitle:

> **Decisioning, Portfolio & Servicing Intelligence**

That combination fits what the Power BI product actually does through Module 2:

- merchant/application profiling;
- governed credit decisioning;
- strategy and structure selection;
- portfolio/cohort intelligence;
- funded-account lifecycle;
- monitoring;
- intervention and servicing;
- economics and decision-effectiveness views.

It also avoids overclaiming. “Credit Intelligence” is broad enough to encompass the current decisioning and servicing architecture without implying that this is a production underwriting platform.

### Recommended naming convention

I would separate the **market-facing product name** from the **technical release identity**:

| Purpose | Name |
|---|---|
| Product/report title | **MSBF Merchant Credit Intelligence** |
| Short name | **MSBF MCI** |
| Subtitle | **Decisioning, Portfolio & Servicing Intelligence** |
| Current scope label | **Module 2 Architecture** |
| Current release identity | **v2.1.0-rc2** |
| PBIX filename while RC | `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix` |
| Final PBIX filename after accepted release | `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0.pbix` |
| GitHub display/folder name | `MSBF Merchant Credit Intelligence` |

For the report footer, I would change the current engineering-style model identity to something like:

> **Model:** MSBF MCI · M2 v2.1.0-rc2

That is much cleaner than:

> `PBI_R26_PARALLEL_REFINEMENT_C2_20260902`

while we can still retain that exact C2/R26 lineage internally in manifests, audit evidence, package receipts, and technical metadata.

## Why I prefer this over the alternatives

**Merchant Finance Intelligence** is a little too broad—it sounds like accounting, treasury, or financial-management analytics.

**Merchant Lending Intelligence** is good, but somewhat narrower and more product-specific.

**Credit Strategy Intelligence** understates the monitoring and servicing architecture.

**Decisioning & Servicing Intelligence** is accurate but sounds more like an internal platform component.

**Merchant Credit Intelligence** is concise, recognizable, and sounds like something a consulting team, fintech, bank, or risk organization could actually present to executives.

It also scales well later. Module 3 can become a deeper enterprise layer **inside the same MSBF Merchant Credit Intelligence product** rather than forcing us to rename the portfolio again.

### I would standardize on this now

For the visible Power BI product:

> **MSBF Merchant Credit Intelligence**  
> *Decisioning, Portfolio & Servicing Intelligence*

For compact footer identity:

> **Model: MSBF MCI · M2 v2.1.0-rc2**

And keep `R26`, `C2`, hashes, and construction lineage **behind the scenes as controlled technical metadata**, not in the client-facing branding.

That is the naming convention I would carry consistently through P03–P06, the final Power BI package, GitHub documentation, screenshots, README material, and eventual release assets.
<!-- END_MESSAGE C118-M00228 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md)
