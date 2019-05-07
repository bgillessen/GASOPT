************************************************************************************************************************************************************
* GASOPT                                                                                                                                                   *
*                                                                                                                                                          *
* Programming: Bastian Gillessen                                                                                                                           *
* PhD Thesis: "Impacts of the "Energiewende" on the German Gas Transmission System" at RWTH Aachen University, Germany                                     *
* Year: 2019                                                                                                                                               *
* Forschungszentrum Jülich                                                                                                                                 *
*                                                                                                                                                          *
************************************************************************************************************************************************************

* IMPORTANT: All flow values related to standard state (T_n = 273.15 K and p_n = 1,01325 bar)
* shown by unit standard cubic meter per second [Nm³/s]
* pressure control stations can be modelled as compressor stations w/o compressor

* Option: Shall an error interval for linearization values be allowed?
scalar BoolEpsFlow   Allow error interval for flow linearization: (1) yes (0) no   /1/;
scalar BoolEpsPress  Allow error interval for pressure linearization: (1) yes (0) no   /1/;

* Set some numbers
scalar
smallM /1e5/
bigM /1e8/
;

* ------------------------------------------------------------------------------
* Generate sets
* ------------------------------------------------------------------------------

Sets

nodeID                                                                          "Node identifiers"

nodeIDAddFeedIn                                                                 "Node identifiers for nodes with additional feed-in"
nodeIDAddFeedOut                                                                "Node identifiers for nodes with additional feed-out"

CSID                                                                            "identifiers of compressor and pressure control station"

ElementID                                                                       "Element identifiers of compressor and pressure control stations"

Configuration                                                                   "Configuration identifiers of compressor and pressure control station"

NodePar                                                                         "Parameters of nodes"
                        /nodeID  "node identifier"
                         dem     "feed-out or -in at node [Nm³/s], feed-out: dem >=0, feed-in: dem <=0"
                         minP    "minimum pressure [bar]"
                         maxP    "maximum pressure [bar]"/

PipePar                                                                         "Parameters of pipes"
                        /L       "Length of pipe [m]"
                         D       "Inner diameter of pipe [m]"
                         k       "Roughness of pipe [mm]"
                         minQIn  "minimum flow [Nm³/s] - in edge direction"
                         maxQIn  "maximum flow [Nm³/s] - in edge direction"
                         minQOpp "minimum flow [Nm³/s] - against edge direction"
                         maxQOpp "maximum flow [Nm³/s] - against edge direction"
                         c2      "pressure loss coefficient [bar²/Nm^6]"/

CSPar                                                                           "Parameters of compressor and pressure control stations"
                        /Exist   "station exists"
                         Switch  "compressor is open (1) or closed (0)"
                         minQ    "minimum flow in configuration [Nm³/s]"
                         maxQ    "maximum flow in configuration [Nm³/s]"
                         minEps  "minimum pressure ratio in configuration [-]"
                         maxEps  "maximum pressure ratio in configuration [-]"
                         FlowDir "flow in (1) or against (0) edge direction"/


PiGridPointsSet                                                                 "Grid points of pressure linearization"

PiGridPointsPar                                                                 "Grid points parameters of pressure linearization"
                         /P
                         Psqr/

QGridPointsSet                                                                  "Grid points of flow linearization"

QGridPointsPar                                                                  "Grid points parameters of flow linearization"
                         /Q
                         Qsqr/

arcType                                                                         "edgeType"
                        /pipe,shortcut,Valve,Compressor,ControlValve/
;

* ------------------------------------------------------------------------------
* Read set values
* ------------------------------------------------------------------------------

$onecho > read_sets.txt
dset=nodeID rng=nodes!A2 rdim=1
dset=NodeIDAddFeedIn rng=nodesFreeFeed!A2 rdim=1
dset=NodeIDAddFeedOut rng=nodesFreeFeed!B2 rdim=1
dset=CSID rng=CompressorStations!D2 rdim=1
dset=ElementID rng=CompressorStations!E2 rdim=1
dset=Configuration rng=CompressorStations!F2 rdim=1
$offecho

$onecho > read_sets_piGridPoints.txt
dset=PiGridPointsSet rng=PiGridPoints!B2 rdim=1
$offecho

$onecho > read_sets_qGridPoints.txt
dset=QGridPointsSet rng=QGridPoints!C2 rdim=1
$offecho

$CALL gdxxrw.exe PiGridPoints.xlsx Squeeze=N @read_sets_piGridPoints.txt trace=3
$GDXIN PiGridPoints.gdx
$LOAD PiGridPointsSet
$GDXIN

$CALL gdxxrw.exe QGridPoints.xlsx Squeeze=N @read_sets_qGridPoints.txt trace=3
$GDXIN QGridPoints.gdx
$LOAD QGridPointsSet
$GDXIN

$CALL gdxxrw.exe OutputBoundStrengthening_stage_1.xlsx Squeeze=N @read_sets.txt trace=3
$GDXIN OutputBoundStrengthening_stage_1.gdx
$LOAD nodeID NodeIDAddFeedIn NodeIDAddFeedOut CSID ElementID Configuration
$GDXIN

alias(nodeID,fromNodeID,toNodeID);

set
shortcut(fromNodeID,toNodeID)
;

display QGridPointsSet, nodeID, NodeIDAddFeedIn,NodeIDAddFeedOut, CSID, ElementID, Configuration, NodePar, PipePar;


* ------------------------------------------------------------------------------
* Generate parameters
* ------------------------------------------------------------------------------

Parameter

pipe(fromNodeID,toNodeID,PipePar)                                               "Pipes"
node(nodeID,NodePar)                                                            "Nodes"
CS(fromNodeID,toNodeID,arcType,CSID,ElementID,Configuration,CSPar)              "Compressor and pressure control stations"
gridP(nodeID,PiGridPointsSet,PiGridPointsPar)                                   "Grid points of pressure linerization"
gridQ(fromNodeID,toNodeID,QGridPointsSet,QGridPointsPar)                        "Grid points of flow linerization"
ComboCSConfigExistHelp(CSID,ElementID,Configuration)                            "Auxiliary parameter to indicate existing configurations in stations"
ElementsSwitchViaConfig(CSID,ElementID,Configuration,CSPar)                     "Elements open or closed in given configuration of stations"
e_Flow_Bnds(fromNodeID,toNodeID)                                                "Allowed error interval of flow [Nm³/s]"
;

scalar
e_Press_Bnds                                                                    "Acceptable error interval of pressure [bar]"
;


* ------------------------------------------------------------------------------
* Read parameters
* ------------------------------------------------------------------------------

$onecho > read_data.txt
par=node rng=nodes!A1 rdim=1 cdim=1
par=pipe rng=pipes!A1 rdim=2 cdim=1
par=CS rng=CompressorStations!A1 rdim=6 cdim=1
set=shortcut rng=shortcuts!A1 rdim=2
par=ComboCSConfigExistHelp rng=CompressorStations!D2 rdim=3
par=ElementsSwitchViaConfig rng=CompressorStations!D1 rdim=3 cdim=1
$offecho

$onecho > read_data_piGridPoints.txt
par=gridP rng=PiGridPoints!A1 rdim=2 cdim=1
par=e_Press_Bnds rng=maxError!A2 dim=0
$offecho

$onecho > read_data_qGridPoints.txt
par=gridQ rng=QGridPoints!A1 rdim=3 cdim=1
par=e_Flow_Bnds rng=maxError!A1 rdim=2
$offecho

$CALL gdxxrw.exe OutputBoundStrengthening_stage_1.xlsx Squeeze=N @read_data.txt trace=3
$GDXIN OutputBoundStrengthening_stage_1.gdx
$LOAD node pipe CS shortcut ComboCSConfigExistHelp ElementsSwitchViaConfig
$GDXIN

$CALL gdxxrw.exe PiGridPoints.xlsx Squeeze=N @read_data_piGridPoints.txt trace=3
$GDXIN PiGridPoints.gdx
$LOAD gridP e_Press_Bnds
$GDXIN

$CALL gdxxrw.exe QGridPoints.xlsx Squeeze=N @read_data_qGridPoints.txt trace=3
$GDXIN QGridPoints.gdx
$LOAD gridQ e_Flow_Bnds
$GDXIN

display gridQ, gridP, CS, node, pipe, shortcut, ComboCSConfigExistHelp, ElementsSwitchViaConfig, e_Flow_Bnds, e_Press_Bnds;


* ------------------------------------------------------------------------------
* Create Tupel (existence of elements)
* ------------------------------------------------------------------------------

parameter
arcExist(fromNodeID,toNodeID,arcType)
arcExistFlowFree(fromNodeID,toNodeID,arcType)
valveExist(fromNodeID,toNodeID,arcType,CSID,ElementID)
compressorExist(fromNodeID,toNodeID,arcType,CSID,ElementID)
controlValveExist(fromNodeID,toNodeID,arcType,CSID,ElementID)
gridpointExistQ(fromNodeID,toNodeID,arcType,QGridPointsSet)
gridpointExistP(nodeID,PiGridPointsSet)
configurationExist(CSID,Configuration)
CSConfigExist(CSID,Configuration)
CSElementExist(CSID,ElementID)
CSCompressorExist(CSID,ElementID)
nodeFeedInFree(nodeID)
nodeFeedOutFree(nodeID)
;

* ------------------------------------------------------------------------------
* Check existence of elements, configurations, etc. for $conditions in
* constraints (equations)
* ------------------------------------------------------------------------------

CSConfigExist(CSID,Configuration)$ComboCSConfigExistHelp(CSID,'Compressor1',Configuration) = yes;
CSConfigExist(CSID,Configuration)$ComboCSConfigExistHelp(CSID,'ControlValve1',Configuration) = yes;

CSElementExist(CSID,ElementID)$ElementsSwitchViaConfig(CSID,ElementID,'1','Exist') = yes;

CSCompressorExist(CSID,'Compressor1')$ElementsSwitchViaConfig(CSID,'Compressor1','1','Exist') = yes;

valveExist(fromNodeID,toNodeID,'Valve',CSID,ElementID)$CS(fromNodeID,toNodeID,'Valve',CSID,ElementID,'1','Exist') = yes;
compressorExist(fromNodeID,toNodeID,'Compressor',CSID,ElementID)$CS(fromNodeID,toNodeID,'Compressor',CSID,ElementID,'1','Exist') = yes;
controlValveExist(fromNodeID,toNodeID,'ControlValve',CSID,ElementID)$CS(fromNodeID,toNodeID,'ControlValve',CSID,ElementID,'1','Exist') = yes;

* Check arc/edge existence

arcExist(fromNodeID,toNodeID,'Pipe')     $pipe(fromNodeID,toNodeID,"L")   = yes;
arcExist(fromNodeID,toNodeID,'Shortcut') $shortcut(fromNodeID,toNodeID)   = yes;

loop((fromNodeID,toNodeID,arcType,CSID,ElementID)$valveExist(fromNodeID,toNodeID,'Valve',CSID,ElementID),
  arcExist(fromNodeID,toNodeID,'Valve') = yes;
);

loop((fromNodeID,toNodeID,arcType,CSID,ElementID)$compressorExist(fromNodeID,toNodeID,'Compressor',CSID,ElementID),
  arcExist(fromNodeID,toNodeID,'Compressor') = yes;
);

loop((fromNodeID,toNodeID,arcType,CSID,ElementID)$controlValveExist(fromNodeID,toNodeID,'ControlValve',CSID,ElementID),
  arcExist(fromNodeID,toNodeID,'ControlValve') = yes;
);

gridpointExistQ(fromNodeID,toNodeID,'Pipe',QGridPointsSet) $gridQ(fromNodeID,toNodeID,QGridPointsSet,'Q')= yes;
gridpointExistP(nodeID,PiGridPointsSet)                    $gridP(nodeID,PiGridPointsSet,'P')=yes

loop(nodeID,
loop(NodeIDAddFeedIn,
if(sameas(nodeID,NodeIDAddFeedIn),
nodeFeedInFree(nodeID) = yes;
break;
else
nodeFeedInFree(nodeID) = no;
);
);
);

loop(nodeID,
loop(NodeIDAddFeedOut,
if(sameas(nodeID,NodeIDAddFeedOut),
nodeFeedOutFree(nodeID) = yes;
break;
else
nodeFeedOutFree(nodeID) = no;
);
);
);

display nodeFeedOutFree, nodeFeedInFree;

display arcExist,valveExist,compressorExist,controlValveExist,gridpointExistQ, gridpointExistP;

display node, pipe, CSConfigExist;

* ------------------------------------------------------------------------------
* Create variables
* ------------------------------------------------------------------------------

Variables
Q(fromNodeID,toNodeID,arcType)                                                  "gas flow [Nm³/s]"
Qsqr(fromNodeID,toNodeID,arcType)                                               "'squared' gas flow |Q|Q"
e_Press(nodeID)                                                                 "allowed error interval pressure [bar²]"
e_Flow(fromNodeID,toNodeID,arcType)                                             "allowed error interval gas flow [Nm^6/s²]"
z                                                                               "objective value"
;

Positive Variable
P(nodeID)                                                                       "pressure [bar]"
Psqr(nodeID)                                                                    "'squared' pressure [bar²]"
lambda_q(fromNodeID,toNodeID,arcType,QGridPointsSet)                            "auxiliary variable for flow linearization"
lambda_p(nodeID,PiGridPointsSet)                                                "auxiliary variable for pressure linearization"
minQCompressor(CSID,ElementID)                                                  "minimum flow of compressor"
maxQCompressor(CSID,ElementID)                                                  "maximum flow of compressor"
AddFeedIn(nodeID)                                                               "Additional feed-in at given node"
AddFeedOut(nodeID)                                                              "Additional feed-out at given node"
;

binary variable
u_q(fromNodeID,toNodeID,arcType,QGridPointsSet)                                 "auxiliary variable for flow linearization"
u_p(nodeID,PiGridPointsSet)                                                     "auxiliary variable for pressure linearization"
u_configuration(CSID,Configuration)                                             "binary variable: (1) configuration is chosen, (0) otherwise"
u_element(CSID,ElementID)                                                       "binary variable: (1) element is open, (0) closed"
;

* ------------------------------------------------------------------------------
* Set upper and lower variable bounds
* ------------------------------------------------------------------------------


lambda_q.lo(fromNodeID,toNodeID,arcType,QGridPointsSet)$gridpointExistQ(fromNodeID,toNodeID,arcType,QGridPointsSet) = 0;
lambda_q.up(fromNodeID,toNodeID,arcType,QGridPointsSet)$gridpointExistQ(fromNodeID,toNodeID,arcType,QGridPointsSet) = 1;

lambda_p.lo(nodeID,PiGridPointsSet)$gridpointExistP(nodeID,PiGridPointsSet) = 0;
lambda_p.up(nodeID,PiGridPointsSet)$gridpointExistP(nodeID,PiGridPointsSet) = 1;

P.lo(nodeID)$gridP(nodeID,'0','P') = node(nodeID,'minP');
P.up(nodeID)$gridP(nodeID,'0','P') = node(nodeID,'maxP');

Psqr.lo(nodeID) = node(nodeID,'minP')**2;
Psqr.up(nodeID) = node(nodeID,'maxP')**2;

Q.lo(fromNodeID,toNodeID,'Pipe')$arcExist(fromNodeID,toNodeID,'Pipe')   = pipe(fromNodeID,toNodeID,'maxQOpp');
Q.up(fromNodeID,toNodeID,'Pipe')$arcExist(fromNodeID,toNodeID,'Pipe')   = pipe(fromNodeID,toNodeID,'maxQIn');

Qsqr.lo(fromNodeID,toNodeID,'Pipe')$arcExist(fromNodeID,toNodeID,'Pipe')   = Q.lo(fromNodeID,toNodeID,'Pipe') * abs(Q.lo(fromNodeID,toNodeID,'Pipe'));
Qsqr.up(fromNodeID,toNodeID,'Pipe')$arcExist(fromNodeID,toNodeID,'Pipe')   = Q.up(fromNodeID,toNodeID,'Pipe') * abs(Q.up(fromNodeID,toNodeID,'Pipe'));

loop((CSID,ElementID)$CSElementExist(CSID,ElementID),
Q.lo(fromNodeID,toNodeID,'ControlValve')$controlValveExist(fromNodeID,toNodeID,'ControlValve',CSID,ElementID) = -smallM;
Q.up(fromNodeID,toNodeID,'ControlValve')$controlValveExist(fromNodeID,toNodeID,'ControlValve',CSID,ElementID) = +smallM;
);

loop((CSID,ElementID)$CSElementExist(CSID,ElementID),
Q.lo(fromNodeID,toNodeID,'Valve')$valveExist(fromNodeID,toNodeID,'Valve',CSID,ElementID) = -smallM;
Q.up(fromNodeID,toNodeID,'Valve')$valveExist(fromNodeID,toNodeID,'Valve',CSID,ElementID) = +smallM;
);

loop((CSID,ElementID)$CSElementExist(CSID,ElementID),
Q.lo(fromNodeID,toNodeID,'Compressor')$compressorExist(fromNodeID,toNodeID,'Compressor',CSID,ElementID) = -smallM;
Q.up(fromNodeID,toNodeID,'Compressor')$compressorExist(fromNodeID,toNodeID,'Compressor',CSID,ElementID) = +smallM;
);


* ------------------------------------------------------------------------------
* Set fix variable values
* ------------------------------------------------------------------------------

loop((fromNodeID,toNodeID)$arcExist(fromNodeID,toNodeID,'Pipe'),
  if(pipe(fromNodeID,toNodeID,'maxQIn') = pipe(fromNodeID,toNodeID,'minQIn') and pipe(fromNodeID,toNodeID,'minQOpp') = 0,
         Q.fx(fromNodeID,toNodeID,'Pipe') = pipe(fromNodeID,toNodeID,'maxQIn');
         Qsqr.fx(fromNodeID,toNodeID,'Pipe') = Q.l(fromNodeID,toNodeID,'Pipe')**2;
  elseif pipe(fromNodeID,toNodeID,'maxQOpp') = pipe(fromNodeID,toNodeID,'minQOpp') and pipe(fromNodeID,toNodeID,'minQIn') = 0,
         Q.fx(fromNodeID,toNodeID,'Pipe') = pipe(fromNodeID,toNodeID,'maxQOpp');
         Qsqr.fx(fromNodeID,toNodeID,'Pipe') = -1 * abs(Q.l(fromNodeID,toNodeID,'Pipe'))**2;
  elseif pipe(fromNodeID,toNodeID,'maxQOpp') = 0 and pipe(fromNodeID,toNodeID,'maxQIn') = 0,
         Q.fx(fromNodeID,toNodeID,'Pipe') = 0;
         Qsqr.fx(fromNodeID,toNodeID,'Pipe') = 0;
  );
);

display Q.lo,Q.up,Qsqr.lo, Qsqr.up, Psqr.lo, Psqr.up, P.lo, P.up;

* ------------------------------------------------------------------------------
* Identify pipes with flow to calculate
* ------------------------------------------------------------------------------


loop((fromNodeID,toNodeID)$arcExist(fromNodeID,toNodeID,'Pipe'),
  if(arcExist(fromNodeID,toNodeID,'Pipe') and Q.lo(fromNodeID,toNodeID,'Pipe') <> Q.up(fromNodeID,toNodeID,'Pipe'),
  arcExistFlowFree(fromNodeID,toNodeID,'Pipe') = yes;
  );
);

* ------------------------------------------------------------------------------
* Set  bounds of error intervals
* ------------------------------------------------------------------------------

if(BoolEpsPress eq 1,
loop(nodeID$gridP(nodeID,'0','P'),
e_Press.lo(nodeID) = -e_Press_Bnds;
e_Press.up(nodeID) = e_Press_Bnds;
);
else
loop(nodeID$gridP(nodeID,'0','P'),
e_Press.lo(nodeID) = 0;
e_Press.up(nodeID) = 0;
);
);

if(BoolEpsFlow eq 1,
loop((fromNodeID,toNodeID,arcType)$arcExistFlowFree(fromNodeID,toNodeID,'pipe'),
e_Flow.lo(fromNodeID,toNodeID,'pipe') = -e_Flow_Bnds(fromNodeID,toNodeID);
e_Flow.up(fromNodeID,toNodeID,'pipe') = e_Flow_Bnds(fromNodeID,toNodeID);
);
else
loop((fromNodeID,toNodeID,arcType)$arcExistFlowFree(fromNodeID,toNodeID,'pipe'),
e_Flow.lo(fromNodeID,toNodeID,'pipe') = 0;
e_Flow.up(fromNodeID,toNodeID,'pipe') = 0;
);
);

display  gridpointExistQ;

display arcExistFlowFree, Q.lo, Q.up, e_Flow.up, e_Flow.lo, e_Press.up, e_Press.lo;

* ------------------------------------------------------------------------------
* Nebenbedingungen (equations) erzeugen
* ------------------------------------------------------------------------------

equations


* nodes
  node_FlowBalance(nodeID)

* pipes - pressure loss

  pipe_PressureEq1(fromNodeID,toNodeID,arcType)

* linear approximation of flow

  pipe_FlowEq1(fromNodeID,toNodeID,arcType)
  pipe_FlowEq2(fromNodeID,toNodeID,arcType)
  pipe_FlowEq3(fromNodeID,toNodeID,arcType,QGridPointsSet)
  pipe_FlowEq4(fromNodeID,toNodeID,arcType,QGridPointsSet)

* linear approximation of pressure
  node_PressEq1(nodeID)
  node_PressEq2(nodeID)
  node_PressEq3(nodeID,PiGridPointsSet)
  node_PressEq4(nodeID,PiGridPointsSet)

* shortcuts
  shortcutEq1(fromNodeID,toNodeID,arcType)

* compressor stations - configurations
  CS_configurationEq1(CSID)
  CS_configurationEq2(CSID,ElementID)
  CS_configurationEq3(CSID,ElementID)
  CS_configurationEq4(CSID,ElementID)
  CS_configurationEq5(CSID,ElementID)
  CS_configurationEq6(fromNodeID,toNodeID,arcType,CSID,ElementID)
  CS_configurationEq7(fromNodeID,toNodeID,arcType,CSID,ElementID)


* compressor stations: valves
  CS_valveEq1(fromNodeID,toNodeID,arcType,CSID,ElementID)
  CS_valveEq2(fromNodeID,toNodeID,arcType,CSID,ElementID)
  CS_valveEq3(fromNodeID,toNodeID,arcType,CSID,ElementID)
  CS_valveEq4(fromNodeID,toNodeID,arcType,CSID,ElementID)

* compressor stations: compressors
  CS_compressorEq1(fromNodeID,toNodeID,arcType,CSID,ElementID)
  CS_compressorEq2(fromNodeID,toNodeID,arcType,CSID,ElementID)
  CS_compressorEq3(fromNodeID,toNodeID,arcType,CSID,ElementID,Configuration)
  CS_compressorEq4(fromNodeID,toNodeID,arcType,CSID,ElementID,Configuration)

* compressor stations: control valves
  CS_controlValveEq1(fromNodeID,toNodeID,arcType,CSID,ElementID,Configuration)
  CS_controlValveEq3(fromNodeID,toNodeID,arcType,CSID,ElementID)
  CS_controlValveEq4(fromNodeID,toNodeID,arcType,CSID,ElementID)

* objective function (auxiliary function)
  objectFun                                                                     

;


*-------------------------------------------------------------------------------
* constraints: nodes
*-------------------------------------------------------------------------------

node_FlowBalance(nodeID)  ..

   sum((toNodeID,arcType),Q(nodeID,toNodeID,arcType)$arcExist(nodeID,toNodeID,arcType))
-  sum((fromNodeID,arcType),Q(fromNodeID,nodeID,arcType)$arcExist(fromNodeID,nodeID,arcType))
+ node(nodeID,'dem') - AddFeedIn(nodeID)$nodeFeedInFree(nodeID) + AddFeedOut(nodeID)$nodeFeedOutFree(nodeID)
=e=
0
;

*-------------------------------------------------------------------------------
* constraints: pressure loss in pipe
*-------------------------------------------------------------------------------

pipe_PressureEq1(fromNodeID,toNodeID,'pipe')$arcExist(fromNodeID,toNodeID,'pipe')..

  Psqr(toNodeID) - Psqr(fromNodeID) =e= pipe(fromNodeID,toNodeID,'c2')* Qsqr(fromNodeID,toNodeID,'pipe')
;

*-------------------------------------------------------------------------------
* constraints: linear approximation of flow in pipes
*-------------------------------------------------------------------------------


pipe_FlowEq1(fromNodeID,toNodeID,'pipe')$arcExistFlowFree(fromNodeID,toNodeID,'pipe')..

  Q(fromNodeID,toNodeID,'pipe')
=e=
  gridQ(fromNodeID,toNodeID,'0','Q') + sum(QGridPointsSet$(ord(QGridPointsSet) > 1 and gridpointExistQ(fromNodeID,toNodeID,'Pipe',QGridPointsSet)),lambda_q(fromNodeID,toNodeID,'Pipe',QGridPointsSet) * (gridQ(fromNodeID,toNodeID,QGridPointsSet,'Q') - gridQ(fromNodeID,toNodeID,QGridPointsSet-1,'Q')))
;


pipe_FlowEq2(fromNodeID,toNodeID,'pipe')$arcExistFlowFree(fromNodeID,toNodeID,'pipe')..

  Qsqr(fromNodeID,toNodeID,'pipe')
=e=
  gridQ(fromNodeID,toNodeID,'0','Qsqr') + sum(QGridPointsSet$(ord(QGridPointsSet) > 1 and gridpointExistQ(fromNodeID,toNodeID,'Pipe',QGridPointsSet)),lambda_q(fromNodeID,toNodeID,'Pipe',QGridPointsSet) * (gridQ(fromNodeID,toNodeID,QGridPointsSet,'Qsqr') - gridQ(fromNodeID,toNodeID,QGridPointsSet-1,'Qsqr')))
  +
  e_Flow(fromNodeID,toNodeID,'pipe')
;



pipe_FlowEq3(fromNodeID,toNodeID,'Pipe',QGridPointsSet)$(ord(QGridPointsSet) > 1 and gridpointExistQ(fromNodeID,toNodeID,'Pipe',QGridPointsSet)) ..

  u_q(fromNodeID,toNodeID,'Pipe',QGridPointsSet) =l= lambda_q(fromNodeID,toNodeID,'Pipe',QGridPointsSet)
;


pipe_FlowEq4(fromNodeID,toNodeID,'Pipe',QGridPointsSet)$(ord(QGridPointsSet) > 1  and gridpointExistQ(fromNodeID,toNodeID,'Pipe',QGridPointsSet)) ..

 lambda_q(fromNodeID,toNodeID,'Pipe',QGridPointsSet) =l=  u_q(fromNodeID,toNodeID,'Pipe',QGridPointsSet-1)
;


*-------------------------------------------------------------------------------
* constraints: linear approximation of pressure in compressor nodes
*-------------------------------------------------------------------------------

node_PressEq1(nodeID)$gridP(nodeID,'0','P')..

  P(nodeID)
=e=
  gridP(nodeID,'0','P') + sum(PiGridPointsSet$(ord(PiGridPointsSet) > 1 and ord(PiGridPointsSet) < card(PiGridPointsSet) and gridpointExistP(nodeID,PiGridPointsSet)),lambda_p(nodeID,PiGridPointsSet) * (gridP(nodeID,PiGridPointsSet,'P') - gridP(nodeID,PiGridPointsSet-1,'P')))
;


node_PressEq2(nodeID)$gridP(nodeID,'0','P')..

  Psqr(nodeID)
=e=
  gridP(nodeID,'0','Psqr') + sum(PiGridPointsSet$(ord(PiGridPointsSet) > 1 and ord(PiGridPointsSet) < card(PiGridPointsSet) and gridpointExistP(nodeID,PiGridPointsSet)),lambda_p(nodeID,PiGridPointsSet) * (gridP(nodeID,PiGridPointsSet,'Psqr') - gridP(nodeID,PiGridPointsSet-1,'Psqr')))
  +
  e_Press(nodeID)
;


node_PressEq3(nodeID,PiGridPointsSet)$(ord(PiGridPointsSet) > 1 and gridpointExistP(nodeID,PiGridPointsSet)) ..

  u_p(nodeID,PiGridPointsSet) =l= lambda_p(nodeID,PiGridPointsSet)
;


node_PressEq4(nodeID,PiGridPointsSet)$(ord(PiGridPointsSet) > 1 and gridpointExistP(nodeID,PiGridPointsSet) and ord(PiGridPointsSet) < card(PiGridPointsSet)) ..

  lambda_p(nodeID,PiGridPointsSet) =l= u_p(nodeID,PiGridPointsSet-1)
;

*-------------------------------------------------------------------------------
* constraints: shortcuts - input pressure equals output pressure
*-------------------------------------------------------------------------------


shortcutEq1(fromNodeID,toNodeID,'Shortcut')$arcExist(fromNodeID,toNodeID,'Shortcut') ..

  Psqr(fromNodeID) =e= Psqr(toNodeID)
;

*-------------------------------------------------------------------------------
* constraints: compressor station - configuration and elements
*-------------------------------------------------------------------------------

* only one active configuration per station

CS_configurationEq1(CSID)$CSCompressorExist(CSID,'Compressor1') ..

  sum(Configuration$CSConfigExist(CSID,Configuration),u_configuration(CSID,Configuration)) =e= 1
;


* switch elements
CS_configurationEq2(CSID,ElementID)$CSElementExist(CSID,ElementID) ..

  sum(Configuration$CSConfigExist(CSID,Configuration),ElementsSwitchViaConfig(CSID,ElementID,Configuration,'Switch') * u_configuration(CSID,Configuration)) =g= u_element(CSID,ElementID)
;


CS_configurationEq3(CSID,ElementID)$CSElementExist(CSID,ElementID) ..

  sum(Configuration$CSConfigExist(CSID,Configuration),(1 - ElementsSwitchViaConfig(CSID,ElementID,Configuration,'Switch')) * u_configuration(CSID,Configuration)) =g= 1 - u_element(CSID,ElementID)
;


* flow bounds of compressors
CS_configurationEq4(CSID,'Compressor1') ..

  sum(Configuration$CSConfigExist(CSID,Configuration),ElementsSwitchViaConfig(CSID,'Compressor1',Configuration,'minQ') * u_configuration(CSID,Configuration)) =e= minQCompressor(CSID,'Compressor1')
;


CS_configurationEq5(CSID,'Compressor1') ..

  sum(Configuration$CSConfigExist(CSID,Configuration),ElementsSwitchViaConfig(CSID,'Compressor1',Configuration,'maxQ') * u_configuration(CSID,Configuration)) =e= maxQCompressor(CSID,'Compressor1')
;


* gas flow direction from configuration
CS_configurationEq6(fromNodeID,toNodeID,arcType,CSID,ElementID)$CS(fromNodeID,toNodeID,arcType,CSID,ElementID,'1','Exist') ..

  (1 + sum((Configuration)$ElementsSwitchViaConfig(CSID,ElementID,Configuration,'Exist'),CS(fromNodeID,toNodeID,arcType,CSID,ElementID,Configuration,'FlowDir')*u_configuration(CSID,Configuration))) * Q.up(fromNodeID,toNodeID,arcType)
  =g=
  Q(fromNodeID,toNodeID,arcType)
;

CS_configurationEq7(fromNodeID,toNodeID,arcType,CSID,ElementID)$CS(fromNodeID,toNodeID,arcType,CSID,ElementID,'1','Exist') ..

  (1 - sum((Configuration)$ElementsSwitchViaConfig(CSID,ElementID,Configuration,'Exist'),CS(fromNodeID,toNodeID,arcType,CSID,ElementID,Configuration,'FlowDir')*u_configuration(CSID,Configuration))) * Q.lo(fromNodeID,toNodeID,arcType)
  =l=
  Q(fromNodeID,toNodeID,arcType)
;


*-------------------------------------------------------------------------------
* constraints: compressor stations - valves
*-------------------------------------------------------------------------------

CS_valveEq1(fromNodeID,toNodeID,'Valve',CSID,ElementID)$valveExist(fromNodeID,toNodeID,'Valve',CSID,ElementID) ..

  bigM * u_element(CSID,ElementID) =g= Q(fromNodeID,toNodeID,'Valve')
;


CS_valveEq2(fromNodeID,toNodeID,'Valve',CSID,ElementID)$valveExist(fromNodeID,toNodeID,'Valve',CSID,ElementID) ..

  -bigM * u_element(CSID,ElementID) =l= Q(fromNodeID,toNodeID,'Valve')
;


CS_valveEq3(fromNodeID,toNodeID,'Valve',CSID,ElementID)$valveExist(fromNodeID,toNodeID,'Valve',CSID,ElementID) ..

  (Psqr.up(toNodeID) - Psqr.lo(fromNodeID)) * u_element(CSID,ElementID)
  +
  Psqr(toNodeID) - Psqr(fromNodeID)
  =l=
  Psqr.up(toNodeID) - Psqr.lo(fromNodeID)
;


CS_valveEq4(fromNodeID,toNodeID,'Valve',CSID,ElementID)$valveExist(fromNodeID,toNodeID,'Valve',CSID,ElementID) ..

  (Psqr.up(fromNodeID) - Psqr.lo(toNodeID)) * u_element(CSID,ElementID)
  +
  Psqr(fromNodeID) - Psqr(toNodeID)
  =l=
  Psqr.up(fromNodeID) - Psqr.lo(toNodeID)
;


*-------------------------------------------------------------------------------
* constraints: compressor stations - compressors
*-------------------------------------------------------------------------------

CS_compressorEq1(fromNodeID,toNodeID,'compressor',CSID,'Compressor1')$compressorExist(fromNodeID,toNodeID,'Compressor',CSID,'Compressor1') ..

  Q(fromNodeID,toNodeID,'compressor') =g= minQCompressor(CSID,'Compressor1')
;


CS_compressorEq2(fromNodeID,toNodeID,'compressor',CSID,'Compressor1')$compressorExist(fromNodeID,toNodeID,'Compressor',CSID,'Compressor1') ..

  Q(fromNodeID,toNodeID,'compressor') =l=  maxQCompressor(CSID,'Compressor1')
;

CS_compressorEq3(fromNodeID,toNodeID,'compressor',CSID,'Compressor1',Configuration)$CS(fromNodeID,toNodeID,'Compressor',CSID,'Compressor1',Configuration,'Exist') ..

  P(toNodeID) =g= ElementsSwitchViaConfig(CSID,'Compressor1',Configuration,'minEps')$ElementsSwitchViaConfig(CSID,'Compressor1',Configuration,'Switch') * P(fromNodeID) - (1 - u_element(CSID,'Compressor1')) * bigM - (1 - u_configuration(CSID,Configuration)) * bigM
;

CS_compressorEq4(fromNodeID,toNodeID,'compressor',CSID,'Compressor1',Configuration)$CS(fromNodeID,toNodeID,'Compressor',CSID,'Compressor1',Configuration,'Exist') ..

  P(toNodeID) =l= ElementsSwitchViaConfig(CSID,'Compressor1',Configuration,'maxEps')$ElementsSwitchViaConfig(CSID,'Compressor1',Configuration,'Switch') * P(fromNodeID) + (1 - u_element(CSID,'Compressor1')) * bigM + (1 - u_configuration(CSID,Configuration)) * bigM
;

*-------------------------------------------------------------------------------
* constraints: compressor stations - control valves
*-------------------------------------------------------------------------------

CS_controlValveEq1(fromNodeID,toNodeID,'ControlValve',CSID,ElementID,Configuration)$(CS(fromNodeID,toNodeID,'ControlValve',CSID,ElementID,Configuration,'FlowDir') eq 1) ..

*  Psqr(toNodeID) - Psqr(fromNodeID) =l= (1 - u_configuration(CSID,configuration)) * bigM
  Psqr(toNodeID) - Psqr(fromNodeID) =l= (1 - u_element(CSID,ElementID)) * bigM
;


$ontext
CS_controlValveEq2(fromNodeID,toNodeID,'ControlValve',CSID,ElementID,Configuration)$(CS(fromNodeID,toNodeID,'ControlValve',CSID,ElementID,Configuration,'FlowDir') eq -1) ..

*  Psqr(fromNodeID) - Psqr(toNodeID) =l= (1 - u_configuration(CSID,configuration)) * bigM
  Psqr(fromNodeID) - Psqr(toNodeID) =l= (1 - u_element(CSID,ElementID)) * bigM
* + (1 - u_element(CSID,ElementID)) * bigM
;
$offtext


CS_controlValveEq3(fromNodeID,toNodeID,'ControlValve',CSID,ElementID)$controlValveExist(fromNodeID,toNodeID,'ControlValve',CSID,ElementID) ..

  Q(fromNodeID,toNodeID,'ControlValve') =l=  u_element(CSID,ElementID) * Q.up(fromNodeID,toNodeID,'ControlValve')
;


CS_controlValveEq4(fromNodeID,toNodeID,'ControlValve',CSID,ElementID)$controlValveExist(fromNodeID,toNodeID,'ControlValve',CSID,ElementID) ..

  Q(fromNodeID,toNodeID,'ControlValve') =g=  u_element(CSID,ElementID) * Q.lo(fromNodeID,toNodeID,'ControlValve')
;


*-------------------------------------------------------------------------------
* objective function
*-------------------------------------------------------------------------------

objectFun ..

z =e= sum(nodeID,Psqr(nodeID));

* if additional flows shall be maximized
*z =e= sum(nodeID$nodeFeedInFree(nodeID),AddFeedIn(nodeID));
*z =e= sum(nodeID$nodeFeedOutFree(nodeID),AddFeedOut(nodeID));


*-------------------------------------------------------------------------------
* Generate model
*-------------------------------------------------------------------------------

model GasTransport /all/;

* use option file cplex.opt
GasTransport.optfile = 1;

*scale model
GasTransport.scaleopt = 1;

* Use cplex as solver // change if necessary
options MIP = CPLEX;


*-------------------------------------------------------------------------------
* Settings for .lst file
*-------------------------------------------------------------------------------

option
limrow = 10000
limcol = 10000
;


*-------------------------------------------------------------------------------
* Solve model
*-------------------------------------------------------------------------------

solve GasTransport using MIP maximizing z;

*-------------------------------------------------------------------------------
* Write results to excel file
*-------------------------------------------------------------------------------

display Q.l, Q.lo, Qsqr.lo, Qsqr.up, Psqr.lo, Psqr.up;

parameter
PprintUp(nodeID)
PprintL(nodeID)
PprintLo(nodeID)
;

loop(nodeID,
PprintUp(nodeID) = sqrt(Psqr.up(nodeID));
PprintL(nodeID) = sqrt(Psqr.l(nodeID));
PprintLo(nodeID) = sqrt(Psqr.lo(nodeID));
);

$onecho > write_GASOPT_MIP_stage_1_results.txt
var = q.lo rng=q!A1 rdim=2 cdim=1
var = q.l  rng=q!I1 rdim=2 cdim=1
var = q.up rng=q!Q1 rdim=2 cdim=1
par = PprintLo rng=p!A1 rdim=1
par = PprintL rng=p!D1 rdim=1
par = PprintUp rng=p!G1 rdim=1
var = u_configuration.l rng=CS_configuration!A1 rdim=2
var = u_element.l rng=CS_element!A1 rdim=2
$offecho

execute_unload "GASOPT_MIP_stage_1_results.gdx";

execute 'gdxxrw.exe GASOPT_MIP_stage_1_results.gdx o=GASOPT_MIP_stage_1_results.xlsx Squeeze=N @write_GASOPT_MIP_stage_1_results.txt';


*-------------------------------------------------------------------------------
* end
*------------------------------------------------------------------------------



