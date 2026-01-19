## Overview

We evaluated top-tier LLMs and specialized agents across three difficulty levels. The benchmark tests AI agents' capabilities in **multi-source synthesis**, **implicit reasoning**, and **real-time web navigation**.

### Leaderboard

![Benchmark Results](https://assets.dinq.me/uploads/images/e6e175bf-fc90-4f68-87a2-1bd7f1303bc5/1767948209_Snipaste_2026-01-09_16-34-04.png)

## What is AI-TSB?

AI-TSB is a **specialized stress test** for AI agents designed to evaluate their capability to handle real-world talent search tasks on the live internet.

### Key Differentiators

**vs. Generic Search (e.g., Google)**
Google returns links. AI-TSB agents must **read, verify, and synthesize** information from multiple sources.

**vs. General Agent Benchmarks (e.g., WebArena)**
WebArena tests UI interaction. AI-TSB tests **cognitive depth** — the ability to reason across fragmented, noisy web data.

## Challenge Levels

### Level 1: Fact Checking

**Objective:** Instant verification of current roles, companies, and affiliations.

**Why it matters:**
In real-world recruiting, verifying basic facts should be instant. Agents often fail by hallucinating outdated information or mixing up similar names.

**Scoring Formula:**
```python
Score = Accuracy × LatencyFactor
LatencyFactor = max(0, 1 - 0.1 × (Time - 5s))
```

*Any response taking longer than 15 seconds receives a score of 0, regardless of correctness.*

#### Case Study: L1_05

**Query:** "Who is the CEO of Anthropic?"

**Expected Answer:** Dario Amodei (as of 2025)

**Common Failure:** Many models hallucinate "Daniela Amodei" (President, not CEO) or retrieve outdated information.

**Evaluation Metric Weights:**

| Metric     | Weight |
| ---------- | ------ |
| Precision  | 50%    |
| Recall     | 20%    |
| Enrichment | 20%    |
| Latency    | 10%    |

> Speed matters. >15s latency results in 0 points for speed.

### Level 2: Logical Screening

**Objective:** Multi-constraint filtering with boolean logic.

**Why it matters:**
Recruiters use complex filters (e.g., "DeepMind engineers who graduated from MIT"). Agents typically suffer from "Attention Drift," ignoring the 2nd or 3rd constraint to maximize recall at the cost of precision.

#### Case Study: L2_12

**Query:** "Find AI Engineers at **DeepMind** who also graduated from **MIT**."

**Verification Logic:**
1. Current Company == "Google DeepMind"
2. Education History contains "MIT" or "Massachusetts Institute of Technology"

**Common Failure:** Models return:
- DeepMind employees from *Stanford* (ignores MIT constraint)
- MIT grads at *OpenAI* (ignores DeepMind constraint)

**Evaluation Metric Weights:**

| Metric     | Weight |
| ---------- | ------ |
| Precision  | 60%    |
| Recall     | 20%    |
| Enrichment | 20%    |
| Latency    | 0%     |

> Accuracy is king. Strict boolean logic enforcement.

### Level 3: Deep Reasoning

**Objective:** Multi-hop reasoning to find "hidden" talent not discoverable through keyword search.

**Why it matters:**
Top talent is often hidden. Finding them requires deducing implicit relationships (e.g., "co-author of X paper but not listed in main credits").

#### Case Study: L3_08

**Query:** "Find the 'hidden author' of the **Qwen technical report** who is not listed in the main author block but contributed significantly to the codebase."

**Required Reasoning Chain:**

1. **Step 1:** Retrieve Qwen technical report & extract author list
2. **Step 2:** Locate Qwen GitHub repository
3. **Step 3:** Analyze commit history for high-frequency contributors **NOT** in Step 1

**Evaluation:** Scored by **LLM-as-a-Judge** based on:
- Completeness of evidence chain (30%)
- Validity of identified contributor (50%)
- Logical coherence (20%)

**Evaluation Metric Weights:**

| Metric     | Weight |
| ---------- | ------ |
| Reasoning  | 50%    |
| Precision  | 30%    |
| Recall     | 10%    |
| Enrichment | 10%    |

> LLM Judge evaluates the logical chain and evidence.

## Methodology

### Hybrid Scoring System

Our evaluation framework combines **deterministic verification** (L1, L2) with **LLM-as-a-Judge semantic evaluation** (L3).

#### Level 1: Latency-Aware Accuracy

Speed is as critical as accuracy for fact-checking. We penalize slow responses non-linearly.

#### Level 2: Weighted F1 Score

To combat "resume spamming" (high recall, low precision), we prioritize **Precision** over **Recall** with weighted F1.

#### Level 3: Semantic Chain Evaluation

A fine-tuned **GPT-4o** judges the agent's reasoning trace:

| Component | Weight |
|-----------|--------|
| Correctness | 50% |
| Evidence Quality | 30% |
| Logic Coherence | 20% |

### Evaluation Pipeline

#### 1. Live Web Injection

Unlike static benchmarks (e.g., Mind2Web), AI-TSB agents must navigate the **live internet**, handling:
- Dynamic DOMs
- CAPTCHAs
- Paywalls (LinkedIn, Twitter)

#### 2. Trace Recording

We record the full execution trace:
- Search queries issued (Google/Bing)
- URLs visited & dwell time
- DOM interactions (clicks, scrolls)
- Final JSON output structure

#### 3. Ground Truth Verification

The final output is compared against a manually curated **Golden Dataset**.

For L3 queries, we verify **provenance**: Did the agent actually visit the GitHub commit page, or did it hallucinate the author based on the README?

### Anti-Gaming Measures

To prevent memorization, **30% of the dataset** consists of **dynamic queries** (e.g., "trending repositories this week") that change over time, forcing live retrieval.

## Full Results

Complete performance breakdown across all models and difficulty levels.

<table>
<thead>
<tr>
<th>Model</th>
<th>Level</th>
<th>Total Score</th>
<th>Recall</th>
<th>Precision</th>
<th>Enrichment</th>
<th>Reasoning</th>
<th>Latency (s)</th>
<th>Samples</th>
</tr>
</thead>
<tbody>
<tr>
<td>DeepSeek-V3.2</td>
<td>L1</td>
<td>50.5</td>
<td>13.2</td>
<td>21.7</td>
<td>15.0</td>
<td>-</td>
<td>20.2</td>
<td>20</td>
</tr>
<tr>
<td>DeepSeek-V3.2</td>
<td>L2</td>
<td>81.2</td>
<td>16.2</td>
<td>48.8</td>
<td>16.2</td>
<td>-</td>
<td>16.9</td>
<td>16</td>
</tr>
<tr>
<td>DeepSeek-V3.2</td>
<td>L3</td>
<td>77.8</td>
<td>10.0</td>
<td>18.3</td>
<td>9.4</td>
<td>39.8</td>
<td>60.1</td>
<td>18</td>
</tr>
<tr>
<td>Haiku-4.5</td>
<td>L1</td>
<td>50.0</td>
<td>12.5</td>
<td>22.5</td>
<td>14.0</td>
<td>-</td>
<td>14.7</td>
<td>20</td>
</tr>
<tr>
<td>Haiku-4.5</td>
<td>L2</td>
<td>88.8</td>
<td>17.5</td>
<td>52.5</td>
<td>18.8</td>
<td>-</td>
<td>14.0</td>
<td>16</td>
</tr>
<tr>
<td>Haiku-4.5</td>
<td>L3</td>
<td>60.6</td>
<td>9.4</td>
<td>13.3</td>
<td>6.7</td>
<td>31.2</td>
<td>18.8</td>
<td>18</td>
</tr>
<tr>
<td>Gemini-3-pro</td>
<td>L1</td>
<td>59.5</td>
<td>16.5</td>
<td>25.0</td>
<td>18.0</td>
<td>-</td>
<td>72.6</td>
<td>20</td>
</tr>
<tr>
<td>Gemini-3-pro</td>
<td>L2</td>
<td>76.2</td>
<td>15.0</td>
<td>45.0</td>
<td>16.2</td>
<td>-</td>
<td>74.4</td>
<td>16</td>
</tr>
<tr>
<td>Gemini-3-pro</td>
<td>L3</td>
<td>93.4</td>
<td>10.0</td>
<td>25.7</td>
<td>10.0</td>
<td>47.4</td>
<td>42.7</td>
<td>18</td>
</tr>
<tr>
<td>Exa-Baseline</td>
<td>L1</td>
<td>28.7</td>
<td>16.2</td>
<td>12.5</td>
<td>0.0</td>
<td>-</td>
<td>39.5</td>
<td>20</td>
</tr>
<tr>
<td>Exa-Baseline</td>
<td>L2</td>
<td>67.5</td>
<td>18.8</td>
<td>48.8</td>
<td>0.0</td>
<td>-</td>
<td>39.9</td>
<td>16</td>
</tr>
<tr>
<td>Exa-Baseline</td>
<td>L3</td>
<td>38.3</td>
<td>10.0</td>
<td>8.3</td>
<td>10.0</td>
<td>20.0</td>
<td><strong style="color: red;">8.8</strong></td>
<td>18</td>
</tr>
<tr>
<td>Flowith-Neo</td>
<td>L3</td>
<td>88.5</td>
<td>10.0</td>
<td>27.7</td>
<td>1.4</td>
<td><strong style="color: red;">49.4</strong></td>
<td>-</td>
<td>18</td>
</tr>
<tr style="background-color: #f3f4f6;">
<td><strong>DINQ (OURS)</strong></td>
<td>L1</td>
<td>53.6</td>
<td>17.0</td>
<td>19.6</td>
<td>17.0</td>
<td>-</td>
<td>65.6</td>
<td>20</td>
</tr>
<tr style="background-color: #f3f4f6;">
<td><strong>DINQ (OURS)</strong></td>
<td>L2</td>
<td><strong style="color: red;">97.0</strong></td>
<td><strong style="color: red;">20.0</strong></td>
<td><strong style="color: red;">57.0</strong></td>
<td><strong style="color: red;">20.0</strong></td>
<td>-</td>
<td>37.2</td>
<td>16</td>
</tr>
<tr style="background-color: #f3f4f6;">
<td><strong>DINQ (OURS)</strong></td>
<td>L3</td>
<td>81.6</td>
<td>10.0</td>
<td>22.7</td>
<td>3.9</td>
<td>41.0</td>
<td>58.4</td>
<td>18</td>
</tr>
</tbody>
</table>

## Key Insights

### Insight 1: Specialized Agents Excel at Logical Screening

**DINQ achieves 97.0 on L2**, significantly outperforming general LLMs by avoiding "attention drift" — the tendency to ignore constraints when processing multi-part queries.

### Insight 2: Frontier Models Lead in Deep Reasoning

For L3 tasks requiring **multi-hop reasoning**, models with massive context windows (Gemini-3-pro: 93.4, Flowith-Neo: 88.5) still hold the advantage.

### Insight 3: Latency Remains a Universal Challenge

All agents suffer from high latency on simple fact-checking (L1), highlighting the need for **"System 1 vs System 2" routing** — fast paths for simple queries, deep reasoning for complex ones.