# **SilkomeMD: Generative Design and Molecular Mechanics Characterization of Silk Proteins**

Generative design and molecular mechanics characterization of silk proteins based on unfolding behavior
**Wei Lu** & **Markus J. Buehler**  
Massachusetts Institute of Technology, 77 Massachusetts Ave., Cambridge, MA 02139, USA
**Contact Email**: [mbuehler@mit.edu](mailto:mbuehler@mit.edu)  

This repository contains molecular dynamics (MD) simulation scripts for spider silk proteins, as described in the study:  
*"Generative Design and Molecular Mechanics Characterization of Silk Proteins Based on Unfolding Behavior."*

## **Abstract**
Abstract: Spider silk combines outstanding mechanical properties and lightweight nature. Its biocompatibility and biodegradability make it an excellent biological material for design. These properties stem from the hierarchical structure of spider silk proteins. However, the complexity and diversity of these proteins, alongside limited data and experimentally characterized properties, have constrained the design of silk-based biomaterials. Further, the mechanobiology and impact of these proteins on silk fibers remain underexplored. In this study, novel silk protein sequences are designed through generative model, and their non-linear unfolding behavior and mechanical properties are investigated through molecular dynamics (MD) simulations. Focusing on major ampullate spidroin (MaSp), a dataset is built by collecting sequences from the silkome dataset and augmenting it using SilkomeGPT, a generative model capable of producing novel silk-inspired sequences. Structural predictions are conducted using OmegaFold, with high-fidelity sections extracted. The unfolding responses are assessed via implicit all-atom MD simulations, and corresponding mechanical behaviors are characterized. The computationally effective approach supports the design of spider silk proteins relating specific properties, and the developed dataset enables systematic analysis on spider silk protein covering structural uncertainties, while simulations provide atomic-level insights into silk protein contributions to fiber properties, advancing the mechanobiological understanding of spider silk proteins and supporting applications in diverse fields.

Keywords: Spider silk protein; Spidroin; Biomaterials; Molecular Dynamics Simulation; Deep Learning; Generative Modeling; Materials by Design

<img alt="image" src="https://github.com/user-attachments/assets/9b19688a-cdb6-49ce-b4be-6ddc9e978a93">

## **Usage**
1. Clone the repository:
   ```bash
   git clone https://github.com/[your-username]/SilkomeMD.git
   cd SilkomeMD

2. Use the simulation script
   The simulation scripts are designed to run a single protein data in NAMD by running the main script "./Single_MD/process_single_protein.sh". Required subprocessing scripts for data pre-processing, protein equilibration, protein steered molecular dynamics (SMD), data post-processing, etc. are provided in ./Single_MD/0_codes/.
   sbatch ./Single_MD/process_single_protein.sh
   

## **Key Results**

We developed a cost-effective framework to explore and optimize the design of spider silk proteins for nanomechanical properties related to their unfolding behavior. We first created a dataset that accounts for protein uncertainties, consisting of 2,177 high-fidelity spider silk protein subsections from both natural and augmented novel sequences. Using this dataset, we systematically simulated protein unfolding through consistent MD simulations. We then characterized, collected, and analyzed the nanomechanical properties of these proteins.
Key results and findings based on the dataset analysis, simulation performance, and the nanomechanical properties characterized from MD simulations covering structural uncertainties are summarized below:
•	Dataset development
•	Simulation observations
•	Secondary structure transitions during protein unfolding
•	Nanomechanical property and protein uncertainty analysis

Detailed analysis and results are provided in the paper.

## **Citation**
If you use this repository or the associated data in your work, please cite the following:

### BibTeX
```bibtex
@article{WeiBuehler_2024,
    title   = {Generative design and molecular mechanics characterization of silk proteins based on unfolding behavior},
    author  = {Wei Lu and Markus J. Buehler},
    journal = {Advanced Functional Materials},
    year    = {2024},
    volume  = {},
    number  = {},
    pages   = {},
    doi     = {},
    url     = {}
}

