---
title: Symmetry-Breaking via Nogood Derivation
date: 2024/01/11
tag: ['clpfd', 'optimization']
description: Constraint learning through nogood derivation promises more powerful symmetry handling by accumulating reasons for propagation failures into reusable constraints...
---

# Introduction

## CLP(FD) Paradigm & Limited Symmetry Handling

Constraint Logic Programming over Finite Domains (CLP(FD)) is a popular declarative paradigm for modeling and solving discrete constraint satisfaction problems. By declaratively specifying variables and constraints, modelers can concisely encode complex problems without having to direct a search procedure. This frees them to focus on capturing structure.

However, CLP(FD) solvers have limited facilities for detecting and eliminating variable symmetries within constraint models. Symmetry corresponds to permutations of decision variables that preserve solution validity. Such redundancies bloat the search space and hindering performance. But as a declarative formalism, CLP(FD) lacks native support for deriving and exploiting problem structure to direct the search.

Some CLP(FD) solvers can handle restricted forms of symmetry by allowing constraints to be posted over induced variable partitions. However, this requires the modeler to manually identify symmetric positions. More broadly, solvers lack support for automatically detecting arbitrary variable symmetries or learning implicit constraints that break such symmetries during search.

As a result, substantial symmetric subspaces remain even in models with some handled symmetries. This expanded search space increases proof complexity, hindering performance. More powerful symmetry handling would allow solvers to automatically prune symmetric branches. This could substantially reduce the search space and proof complexity for models with rich symmetries.

## Promise of Nogood Learning

One approach that holds promise for more powerful automated symmetry breaking is nogood learning. This technique allows solvers to accumulate "nogoods", which encode generalized constraints that rule out prior failed search branches. By automatically deriving such implicit constraints, solvers can prune large symmetric subspaces without requiring modelers to manually identify symmetries.

Nogood-based symmetry handling has shown substantial performance gains in Boolean Satisfiability (SAT) solvers. SAT nogood learning schemes allow encountering one failed assignment for a set of symmetric decision variables to prune the entire symmetric subspace. This suggests nogood-based techniques could bring similar benefits to constraint programming.

However, effectively integrating nogood learning poses challenges for CLP(FD).Constraint models richly capture problem structure, so directly translating SAT approaches is inadequate. Efficiently deriving meaningful nogoods requires tracking variable assignments and dependencies within a declaration model. And productively propagating nogoods back into the search process necessitates interfacing with the solver's underlying propagation semantics.

If these challenges can be adequately addressed, nogood learning promises a generalization of symmetry breaking that could substantially expand the power of CLP(FD). By auto-detecting symmetries and effectively pruning symmetric subspaces, proof complexity reductions could greatly accelerate solving. This emerging direction warrants deeper formal exploration into effectively embedding nogood learning.

## Mapping Concepts to Declarative Constraint Modeling

To effectively realize the promise of nogood-driven symmetry handling, key concepts from SAT solving must be appropriately reconciled with the rich structure of constraint models. This requires formalizing connections between the reasoning context in which nogoods are derived and the variable interdependencies expressed in declarative specifications.

Central questions include:

- How can variable-value assignments that result in a propagation failure be generalized into reusable constraints that capture causes of infeasibility?
- What context about the constraint model and current variable domains needs to be encoded to enable meaningful nogood integration?
- How can derived nogoods be correctly propagated to prune subspaces where the same infeasibility causes would be encountered?

Answering these requires formalizing nogoods with respect to:

- The assignment trajectory through a search tree
- The subsets of constraints that contributed to propagations
- The state of variable domains when propagation failures occurred

By mapping key nogood concepts into this modeling dimensionality, the dynamics of declarative model evolution can provide an adequate context foundation for propagating meaningful learned constraints.

This perspective exposes open questions around conceptual alignment, including:

- Reconciling dependency-driven nogood evolution with goal-oriented solver branching
- Interfacing with existing propagator invocation and termination conditions
- Balancing completeness in symmetry pruning with model growth

# Declarative Encoding of Nogoods

## Propositional Encoding of Constraint Violations

A propositional schema for encoding propagations provides a useful starting point for representing nogoods. Individual variable-value assignments can be captured as Boolean propositions. Constraint propagation rules which make certain combinations of assignments infeasible can then be encoded as clauses specifying exclusions.

For example, consider a simple arithmetic constraint:

```
X + Y ≤ 10
```

Along with domains:

```
X ∈ {1..8}, Y ∈ {1..8}
```

The assignment (X = 8, Y = 8) violates this constraint. The negation of this infeasible combination gives the clause:

```
¬(X=8 ∧ Y=8)
```

Generalizing, if a subset of assignments Ai triggers propagator P to prune domains and terminate with failure, the nogood becomes:

```
¬(A1 ∧ ... ∧ An)
```

This propositional representation provides a baseline to encapsulate the essence of a constraint violation. The next challenges are extending this schema to express rich constraint models and adequately capturing derivation context. But the propositional encoding gives a useful paradigm for translating propagations into reusable nogoods.

## First-Order Extension for Rich Constraint Models

While the propositional schema captures basic constraint violations, rich constraint models necessitate a more expressive first-order formulation. Key requirements include:

    Symbolically denoting constrained variables
    Expressing variable interdependencies
    Embedding generalizable constraint semantics

Moving beyond enumerated assignments to capture general classes enables concise representation of reuseable nogoods.

For example, with variables X and Y, arrays A and B, and length L:

```
∀ i ∈ {1..L} . A[i] + B[i] ≤ 10
```

A first-order nogood generalizing an infeasible assignment would become:

```
¬ ∃ i . (A[i] = 8 ∧ B[i] = 8)
```

Here, the universal quantification scopes over the constrained dimensions of the problem. And the existential quantification encodes the essence of the reason for infeasibility.

This shift to first-order logic aligns with the declarative modeling paradigm. Constraints and variable relationships are stated generally. And the encodings can transparently embed within constraint expression languages.

With this capacity to represent rich, reusable semantic structures as nogoods, the remaining challenges relate to managing derivation and integration with search. But the first-order move progresses the conceptual adequacy for constraint learning.

## Example Specification of Derivable Nogoods

Consider a model with variables:
```
{X1, X2, X3}
```

And constraints:

```
    X1 < X2
    X3 = X2 + 1
    X1 + X3 ≤ 5
```

Along with domains:
```
X1 ∈ {1..3}, X2 ∈ {2..4}, X3 ∈ {3..5}
```

Some derivable nogoods:

```
    ¬(X1 = 3 ∧ X2 = 2)
        Violates constraint 1
    ¬(X2 = 4 ∧ X3 = 5)
        Violates constraint 2
    ¬∃i∈{1,2,3}. (X1 = i ∧ X3 = 6 - i)
        Universally violates constraint 3 for valid variable domains
```

This illustrates how both basic propositional violations and more general first-order derivations can emerge. Violated constraints and propagation states get encoded at varying granularities.

As search proceeds and propagators trigger, new nogoods would be incrementally derived. The central questions become how to manage accumulation and reuse of these learned constraints.

But this provides an introductory sketch of derivable nogoods from a simple constraint model. The key challenge is now adequately capturing context to enable correct propagation.

# Capturing Derivation Context

## Dependency Tracking in CP Solvers

To enable correct nogood propagation, solvers must track variable-constraint dependencies. Classical CLP(FD) solvers maintain dependency graphs linking decision variables to posted constraints. This supports tracking the scope of propagations triggered by assignments.

When a variable is assigned, relevant constraints are placed in a propagation queue. Dependencies dictate which propagators are invoked as consequences of decisions. The directed graph captures this flow of inferences.

Tracking these dependencies serves to identify the subset of constraints whose current state led to any propagation failure. Encoding the active constraint set is essential context for generalizing valid nogoods.

For example, given state:

```
X = 3, Y = 2
Constraints {C1, C2} triggered
Leads to failure
```

The context-embedded nogood would be:

```
¬(X=3 ∧ Y=2 | {C1, C2})
```

Capturing the constraints involved in failure helps guide correct reuse in other solver states. This connection between dependency links and derivable reasons forms a key part of the context needed to enable meaningful nogood learning.

## Constraint Retention for Nogood Formalization

In addition to dependency links, Capturing meaningful context for nogoods requires retaining details on current constraint states. Classical CLP(FD) semantics involve fully re-propagating a problem upon backtracking. But for learning, information on the constraints violated by a particular failure must be preserved.

This motivates defining constraint retention policies specifying how much propagator state to maintain across search states and backtracks:

- Full retention: Propagator keeps entire state - all internal structures preserved
- Differential retention: Propagator stores delta of internal changes
- Incremental retention: Propagator remembers subsets of key deductions

Choices involve tradeoffs balancing memory, overhead, and semantic meaning. But some preservation of propagator deduction state is essential for pinpointing sources of conflicts.

Formalizing such retention within an enriched CLP(FD) semantics provides a framework for encapsulating context. Constraints become reasons in addition to domain pruning mechanisms. Their recorded states explain derivations - the "why" to complement the "what".

This justification tracing enables generalizing specific conflicts into reusable nogoods. By aligning propagation rules with retention policies, tractable context embedding appears achievable.

## Structure-Preserving Model Evolution

An enhanced solver semantics must enable incremental derivation of nogoods while preserving the meaningful problem structure represented in constraint models. This requires formally tracking model evolution.

As a solver interleaves search with propagation across models, key aspects of state must be monitored:

- Variable domains - values remaining feasible
- Constraint activity - propagations applied
- Dependency chain - inference sequence
- Nogood accumulation - added learned constraints

Maintaining these evolving structures provides an adequate basis for context embedding without disrupting declarative specifications.

Model evolution trajectories become rich records of infeasibility. By tracing the model state transforming assignments and propagations, nogoods can encode generalized explanations of conflicts.

For example, a model state trajectory would capture:

```
{X1 → C1} ⇒ {X2 → C2} ⇒ ∅
```

With this context, the reason for a final failure can be expressed as:

```
¬(X1=v1 ∧ X2=v2 | C1 ∧ C2)
```

Formalizing such structure-preserving model transformation dynamics allows incrementally accumulating meaningful nogoods referenced to the constraints and decisions driving search.

# Tractable Nogood Accumulation

## Efficient Database Storage Schemes

To build up a critical mass of derived nogoods without excessive overhead, efficient database storage and retrieval mechanisms are needed. As constraints over assignments, nogoods resemble transactional data - rapidly ingested records of propagation events.

Database techniques for managing fast inserts and flexible queries can enable effective accumulation:

- Columnar storage: Vertical decomposition to avoid sparse rows
- Periodic batch commits: Group inserts to optimize write patterns
- Hash/range indexing: Optimized lookup by solver state
- Compression: Exploit repetition in explanations

Applying database approaches leverages scalable infrastructure for accumulating derivation trace context across search states. This keeps nogood insertion, storage, and matching layered away from core solving semantics.

And database principles like normalization can also inform nogood granularity optimizations. Grouping similar explanations balances retention locality with reuse potential.

Combining database techniques with a context-focused nogood representation shows promise for scalable accumulation and lookup without prohibitive overheads. The remaining challenges shift to managing lifetimes and propagation.

## Retention Policies and Matching Granularity

To bound accumulating nogoods, retention policies and matching granularity provide pruning dials. Retention policies dictate what horizons of past derivations to preserve:

- Search depth threshold: Delete nogoods beyond depth k
- Backtrack distance: Retain last n backtrack levels
- Problem structure: Maintain partitions or clusters

And match granularity controls generalization level:

- Instance-based: Ground assignments as constants
- Domain-based: Use current domain values
- Structure-based: Abstract symbolic representations

Balancing these dimensions allows building up histories focused on relevant regions without unbounded growth. For example, a policy could retain the last 10 depths, matching at the domain level.

This scopes accumulation around the active search frontier while supporting generalization. Combined with database storage, configurable graded retention enables amassing meaningful nogoods without prohibitive overhead.

And as search exposes more structure, granularity can incrementally evolve. This allows an adaptive approach keeping infrastructural costs commensurate with descriptive value.

## Pruning and Amortization Strategies

In addition to retention scoping, effective nogood accumulation requires pruning and amortization strategies. Intelligent deletion policies prevent uncontrolled database growth while ensuring useful nogoods remain.

Pruning techniques include:

- Subsumption: Remove subsumed nogoods
- Obsolescence: Delete nogoods invalidated by propagation
- Saturation: Eliminate redundant similar nogoods
- Size limits: Restrict complexity

And amortization schemes write off costs:

- Search depth amortization:
- Charge derivations to depth thresholds
- Backtrack amortization: Allocate across backtrack stack
- Batch amortization: Spread among groups

Guided by these strategies, the nogood store can productively grow within controlled space. Matching complexity can likewise be amortized to avoid overwhelming propagation.

Together with the database mechanisms and retention policies, these approaches bound accumulation overhead while allowing continuous integration of learned explanations. This provides the infrastructure for tractable context-focused nogood derivation at scale.

The remaining challenges relate to search integration and demonstrating formal benefits - but efficient scaling appears achievable.

# Holistic Propagation Semantics

## Formal Model Integrating Nogood Dissemination

With efficient accumulation infrastructure, the central challenge becomes seamlessly integrating reuse of learned nogoods into core solving. This requires interfacing the nogood derivation history with search state progression in a holistic propagation semantics.

The formal model must align declarative constraint posting with imperative decision sequencing. As branches evolve, relevant past nogoods should automatically disseminate to propagate accumulated knowledge.

One approach centers on solver state descriptors - symbolic annotations characterizing search positions. Descriptors can index both derivations and propagator invocations. Unifying these interfaces enables linking propagated states to reuseable explanations.

For example, with descriptor schema:

```
D = {Vars, Domains, Constraints}
```

A derivable nogood would be:

```
¬P(d)
```

Where d is an instance of descriptor D capturing key model facets.

Then a state matching on D can reuse ¬P to prune, activating the accumulated inference chain.

Formalizing such descriptors provides a mechanism for aligning past derivations with reusable propagation rules across search states. This forms a pathway for disseminating generalized explanations without disrupting declarativity.

## Operationalization Scheme Development

Moving beyond the formal model, an operationalization scheme can realizing holistic nogood-based propagation. This bridges the conceptual integration with a feasible solver implementation.

Central mechanisms requiring development include:

- Descriptor indexing for retrieval
- Matching/unification procedures
- Propagator integration protocols
- Queue prioritization policies
- Termination standards

Descriptor indexing enables fast lookups from state annotations to relevant nogoods. Efficient hashing, clustering, and ordering schemas avoid linear scan costs.

Unification procedures check descriptor compatibility between search states and accumulated nogood contexts. Granular policies balance precision and performance.

Protocols govern invoking disseminated nogood propagators - including queuing, triggering, and results handling.

Prioritization policies determine when to activate nogood propagators relative to natively posted constraints.

And global termination standards check when blocking states indicate solving completeness.

Elaborating these algorithms, data structures, and interface standards provides a pathway to leverage the conceptual model integrating declarative search with learned explanations. This facilitates translating formal nogood benefits into empirical solver improvements.

## Alignment with Declarative CP Processing

A key challenge in operationalizing nogood learning is preserving alignment with the declarative propagation model. Core constraint processing should enact inferences purely based on stated variable relationships, independently of search sequencing. Integrating imperative learned rules risks polluting this purity.

Several aspects enable reconciling nogoods with declarativity:

- Content-based rather than control-based - Nogoods augment the constraint store rather than directing search
- Invocation via matching - Reuse driven by state descriptors rather than step ordering
- Transparent accumulation - Database histories independently managed
- Configurable dissemination - Control over learned constraint activation

Additionally, declarativity-preserving policies can govern integration:

- Search parity - Impose no additional branching biases
- Priority neutrality - Balance propagator queue scheduling
- Purity validation - Check equivalence to declarative expansion

Finally, there is an intriguing connection between nogoods as learned constraints and declarative modeling of epistemic restrictions. This suggests a unification - applying problem structure to guide derivation histories.

With intentional design and testing, integrating nogood infrastructure need not disrupt the core constraint-centered processing model. And the interfaces may even enhance modular reasoning. This alignment helps realize performance gains safely.

# Theoretical Benefits Analysis

## Anticipated Pruning of Symmetric Subspaces

A primary motivation for incorporating nogood derivation is enhancing automated symmetry handling. By generalizing reasons for propagation failures, learned constraints can detect and eliminate variable symmetries without manual identification.

The anticipated benefits center on large-scale search space pruning:

- Subspace exclusion - Broadly prune symmetric branches
- Proof compression - Avoid replicating inferences
- Structure inference - Reveal high-level invariants

As an illustration, consider a problem with variables X and Y along with a symmetric subset Z. When exploring with X = x1, if any assignment z ∈ Z causes a failure, the generalized nogood would become:

```
¬(X = x1 ∧ ∃z ∈ Z . (z = v))
```

This single derivation prunes the entire subspace of symmetric decisions under X = x1.

By recursively accumulating such nogoods, substantial fractions of the search tree can get eliminated. And derivations transfer across connected symmetries, potentially decomposing proof complexity.

This projected ability to widely prune symmetric subspaces provides significant motivation for incorporating nogood learning. The further formal questions relate to effectively guiding reuse.

## Projected Proof Complexity Reduction

In addition to directly pruning symmetric subspaces, nogood learning promises to reduce proof complexity through reusing partial derivations. By memoizing explanations of infeasibility, fragments of the justification graph can be eliminated.

This proof compression centers on substituting compact learned constraints for expanded inference chains:

```
(Decisions → Propagations)* → Conflict
```

Becomes:

```
Decisions → Nogood
```

The accumulated inference paths get replaced by reused nogood lookup and matching.

For problems exhibiting recurrence - e.g. the same propagations frequently following similar decisions - this substitution can decompress justifications. Common sub-proofs get coalesced.

In the theorem proving domain, proof sketches leverage this technique - collapsing steps by referring to learned lemmas. Similar complexity reductions are projected from incorporating constraint learning.

This further motivates nogood integration, as decompressing proof complexity has multiplicative benefits on search efficiency. And symmetry handling stands to unlock substational recurring sub-proof elimination.


## Conjectured Exploitation of Problem Structure

In addition to direct symmetry handling, the generalized constraints accumulated from nogood derivation may expose latent problem structure amenable to broader exploitation. By implicitly embedding facets of infeasibility, learned rules summarize key interactions.

This motivates the conjecture that nagood histories can reveal beneficial problem decomposition. Conceptually, decomposition separates out loosely-connected sub-problems, allowing divide-and-conquer solving.

For example, consider a scheduling problem consisting of two loosely interacting clusters of activities. If modeled monolithically, the flat constraint graph could obscure this modularity. But if nogoods repeatedly derive within clusters, decomposition may become evident.

By bifurcating interconnected decision subsets, solving can address disconnected problems independently before reconciling through a coordination interface. Such structure detection would further enhance efficiency.

While promising, realizing this projected emergence of exploitable modularity requires layering additional analysis onto core nogood propagation. Clustering deduction histories and quantifying constraint interactions may expose decomposition opportunities.

This exemplifies the secondary knowledge nogoods may carry - motivating ongoing research into best exploiting this promising paradigm.

# Conclusion & Research Outlook

## Key Takeaways & Avenues for Practical Realization

This conceptual analysis formalizes integrating nogood learning in CLP(FD) as a mechanism for enhancing symmetry handling. By generalizing reasons for propagations failures into reusable constraints, solvers can automatically derive symmetry breaking rules.

Several theoretical directions show promise:

- Declarative representation of learned nogoods
- Embedding derivation context for correctness
- Database accumulation without excessive overhead
- Interfacing with search state progression
- Proof and complexity reduction

Together these constitute a framework for enhancing constraint propagation via accumulated explanation reuse.

Realizing practical gains requires further development in areas including:

- Implementation schemes interfacing search with accumulation
- Granular configurable policies governing reuse
- Empirical evaluation on model classes
- Structure learning and decomposition approaches

There remain open questions regarding model growth and completeness. But the conceptual groundwork suggests nogoods can expand automated symmetry handling for constrained search.

## Connections to Adjacencies in SMT and SAT Modalities

While focused on CLP(FD), nogood derivation connects to extensive work in SAT and SMT on conflict analysis and learning. Similar ideas of proof compression and explanation generalization motivate clause learning in SAT. And theory-specific learning generalizes reasons for theory conflicts.

However, key differences arise in propagating learned constraints into rich declarative models rather than guiding search directly in purely Boolean SAT formulas. Encoding meaningfully reusable propagation histories aligned with constraint structure poses unique challenges.

Still, insights may transfer across these modalities:

- Database techniques from industry SAT solvers
- Efficient implication graph traversal methods
- Theory-focused generalization approaches
- Structure learning mechanisms

In the reverse direction, effectively incorporating declarative context may inform improving literal-level conflict analysis. And automated symmetry handling may inspire new SAT encoding approaches.

By formalizing the space of incremental constraint enrichment, this exploration connects logics programming with high-performance domain-specific reasoning. Continued cross-pollination between these solving paradigms promises to advance automated deduction capabilities.

## An Invitation to Further Foundational Analysis

By formally integrating nogood learning with core CLP(FD) solving, this conceptual formalization opens questions spanning theory, systems, and applications. Both foundational and implementation-focused inquiries have pivotal roles in responsibly realizing performance gains.

Many semantics subtleties remain regarding aligning imperative learned rules with declarative model evolution. And significant engineering challenges stand between these conceptual schemes and efficient solver integration.

However, the magnitude of the potential speedups motivating this exploration warrant continued analysis. Automating more powerful symmetry handling promises substantial proof complexity reductions across difficult combinatorial spaces.

Unlocking such capabilities could dramatically expand applicability of constraint modeling. But this requires proceeding carefully and rigorously. Both practical and theoretical advances are needed to transform these promising directions into responsible solving progress.

Toward that goal, this formulation invites dialogue across communities to elucidate connections and formal subtleties. Continued investigation will help guide translating concepts into practice - unlocking automated deduction advances that ethically expand the scope of tractable reasoning.
