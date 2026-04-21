# Medicare Part D Drug Spending Analysis (2019–2023)

## Overview

An end-to-end analysis of Medicare Part D drug spending using CMS public data
to identify cost drivers, pricing trends, and opportunities for cost optimization
across 14,000+ drug records spanning five years (2019–2023).

This project answers the types of questions a pharmacy benefits analyst, healthcare
FP&A team, or revenue cycle group would face: where is spending concentrated, what
is driving cost increases, and where are the opportunities to reduce costs.

## Dashboard

![Dashboard Preview](dashboard_preview.png)

**[View the interactive dashboard on Tableau Public](https://public.tableau.com/app/profile/virat.mehta3514/vizzes)**

## Key Findings

- **Eliquis (Apixaban)** is the single largest Medicare Part D expenditure at over
  $18.2 billion in 2023, more than double the second-highest drug
- Most high-spend drug cost increases are **volume-driven** (more patients using the
  drug) rather than price-driven, suggesting utilization management may be more
  impactful than price negotiation for cost containment
- Several drugs show sustained 4-year compound annual growth rates exceeding 50%,
  with **Quinidine Sulfate** leading at 105% CAGR — these represent long-term cost
  escalation risks rather than one-time spikes

## SQL Queries

The analysis consists of six queries, each answering a specific business question:

| Query | Business Question |
|-------|------------------|
| 1 | Where is Medicare's drug spending concentrated? (Top 20 by total spend) |
| 2 | Which drugs are experiencing the fastest cost-per-unit inflation? |
| 3 | Are cost increases driven by price hikes or higher utilization? |
| 4 | Where are the biggest opportunities to shift from brand to generic? |
| 5 | Which manufacturers dominate high-spend drug categories? |
| 6 | Which drugs show sustained multi-year cost growth (4-year CAGR)? |

**Technical highlights:** CTEs for modular query structure, window functions
(RANK, OVER) for peer ranking, CASE statements for cost driver classification,
and year-over-year variance decomposition separating price from volume effects.

## Data Source

[CMS Medicare Part D Spending by Drug (2019–2023)](https://data.cms.gov/summary-statistics-on-use-and-payments/medicare-medicaid-spending-by-drug/medicare-part-d-spending-by-drug)

## Tools Used

- **MySQL** — data loading, cleaning, and analysis
- **Tableau Public** — interactive dashboard and data visualization

## About

Built by **Virat Mehta** — Business Intelligence Analyst with experience in
healthcare and financial operations.
