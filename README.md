# GASOPT

A tool for load flow calculation of gas grids using optimization methods. The mathematical approach is inspired by the MILP-relaxation approach in Chapter 6 of the book "Koch, T.; Hiller, B.; Pfetsch, M. E.; Schewe, L. (2015): Evaluating gas network capacities" (ISBN: 978-1-611973-68-6) and "Geißler, B (2011): Towards Globally Optimal Solutions for MINLPs by Discretization Techniques with Applications in Gas Network Optimization" (ISBN: 978-3-8439-0168-0)

GASOPT is developed by Bastian Gillessen within his PhD project "Impacts of the 'Energiewende' on the German Gas Transmission System" and applicated to nation-wide gas infrastructure data. It may inspire others to use this or a similar approach in further projects.

## What it can do

Calculate pressure and flow values of gas flows within a gas grid based on the darcy-weisbach-equation for planning purposes (see: [Wikipedia](https://en.wikipedia.org/wiki/Darcy%E2%80%93Weisbach_equation)). Decisions about open/closed states of active compressor station elements are solved endogenously within the model. 

## How to use it

The released code is developed and tested for GAMS 25.0.2 with CPLEX 12.7.0 (see: [GAMS](https://www.gams.com/) and [CPLEX](https://www.ibm.com/de-de/products/ilog-cplex-optimization-studio)). Other MILP solvers than CPLEX might be used. Run stage 1 and stage 2 consecutively. Results are stored in "GASOPT_MIP_stage_1_results.xlsx" and/or "GASOPT_MIP_stage_1_results.xlsx"

## provided example

Examplaric data is provided in order to make the code comprehensible (see also Example.pdf). The values provided  do not have the presumption to be physically correct. 

Two program files are released ("GASOPT_MIP_stage_1.gms" and "GASOPT_MIP_stage_1.gms"). The only difference is that the second stage reads the compressor station states from the solution file of the first stage. So solution space reduces significantly in comparison to stage 1 which might be used by modellers to refine necessary linearizations. 

Necessary linearization data is provided for the pressure of compressor nodes in "PiGridPoints.xlsx" and for the gas flow of pipes in "QGridPoints.xlsx". The flow in branches of the grid topology might be fixed in the input data with setting the parameters of maxQIn and maxQOpp in file "OutputBoundStrengthening_stage_1/2.xlsx" (sheet 'pipes') to the same values. 

Further relevant pipe parameters are length L in m, inner diameter D in m, roughness k in mm and pressure loss parameter c2 (see given sources). All flow values are given in m³/s in standard state. Node parameters are minimum and maximum absolute pressure minP and maxP in bar. Feed-in data is given as negative values and feed-out data as positive values for dem in m³/s. The sum of feed-ins must equal the sum of feed-outs.

Shortcuts might be used to model grid elements without physical dimension.

Compressor stations are modelled with a list of configurations that store information of open/closed elements per configuration. The minEps and maxEps value sets the minimum and maximum pressure ratio of compressors. Valves and control valves differ as control valves can reduce the pressure when open.


