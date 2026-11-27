# Architecture snippet (DRAFT, Oct 28, 2026)

The live map is in the README. This file is the draft note. Names come from the Terraform files. `backend.tf` exists. Nothing is applied yet. GitHub Actions stays unwired until the three Azure secrets and the projects map are set.

```mermaid
flowchart LR
    laptop["Your laptop<br/>terraform apply · Azure CLI login"]
    gha["GitHub Actions + shared pipeline<br/>not wired yet"]
    inbox["Owner's inbox"]

    subgraph sub["Azure subscription"]
        budget["budget-cost-zeon01<br/>Subscription budget · $200 a month"]
        actlog["Subscription activity log<br/>Administrative · Security · Policy"]
        diag["diag-cost-zeon01<br/>Diagnostic setting"]
        subgraph rg["rg-cost-poc-zeon01"]
            ag["ag-cost<br/>Action group"]
            logic["logic-cost<br/>Logic App · empty container"]
            law["log-cost<br/>Log Analytics workspace"]
            wb["Cost workbook<br/>not written yet"]
        end
    end

    budget -- "alert at $50 · $100 · $200" --> ag
    ag -- "email" --> inbox
    ag -. "not connected" .-> logic
    logic -. "Office 365 email step · portal click" .-> inbox
    actlog -- "copies events" --> diag
    diag -- "activity logs" --> law
    law -. "query · planned" .-> wb
    laptop -- "terraform apply" --> sub
    gha -. "plan + apply · group contents only" .-> rg

    classDef azure fill:#0078d4,stroke:#005a9e,color:#fff
    classDef external fill:#6e7681,stroke:#484f58,color:#fff
    classDef planned fill:#fff,stroke:#0078d4,color:#1f2328,stroke-dasharray:4 4

    class budget,actlog,diag,ag,logic,law azure
    class laptop,inbox external
    class gha,wb planned
```

*Caption: The subscription budget warns the action group at $50, $100 and $200 of actual spend, and the action group emails the owner. The activity log is copied into a Log Analytics workspace by a subscription-level diagnostic setting. The budget and that setting sit outside the resource group, so the nightly delete skips them and the pipeline cannot create them; they are applied from the laptop. The Logic App's email step is a portal click and is not connected to the action group.*

## Before this goes in the README

- [ ] Redraw the design picture from the finished files and save it as `architecture.png` and `architecture.pdf` (the `-draft` files are placeholders).
- [ ] Add the Cost workbook once the query is approved, and move it out of the dotted state.
- [ ] Remove the "not wired yet" labels when `backend.tf` and the three GitHub secrets exist.
- [ ] Check it renders on the GitHub repo page, in light and dark mode.
