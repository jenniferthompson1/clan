{smcl}
{* *! version 1.0)}
{hline}
{cmd:help clan}{right: ({})}
{hline}
{vieweralsosee "[R] mixed" "help mixed"}{...}
{viewerjumpto "Syntax" "clan##syntax"}{...}
{viewerjumpto "Menu" "clan##menu"}{...}
{viewerjumpto "Description" "clan##description"}{...}
{viewerjumpto "Options" "clan##options"}{...}
{viewerjumpto "Examples" "clan##examples"}{...}
{viewerjumpto "Stored results" "clan##results"}{...}
{viewerjumpto "Authors" "clan##authors"}{...}

{title:Title}
{p2colset 5 20 20 2}{...}
{p2col :{hi:clan} {hline 2}}Cluster-level analysis of data from Cluster Randomised Trials{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:clan}
        {it:{help depvar}}
        {it:{help indepvars}}
		{ifin}
        {cmd:,}
        {opth arm(varname)}
        {opth clus:ter(varname)}
        {opt eff:ect(s)}
        [{it:options}]

{synoptset 29 tabbed}{...}
{marker options}
{marker options_table}{...}
{synopthdr}
{synoptline}
{syntab : Main}
{p2coldent :* {opth arm(varname)}}variable defining the (two) trial arms{p_end}
{p2coldent :* {opth clus:ter(varname)}}variable defining the clusters{p_end}
{p2coldent :* {opth eff:ect(clan##effspec:effect)}}a descriptor telling {cmd:clan} which effect estimate you want to produce{p_end}
{synopt :{opth str:ata(varname)}}variable defining the (single) stratification factor used in the trial{p_end}
{synopt :{opt fup:time(varname)}}variable describing the follow-up time in trials wher ethe outcome is time-to-event{p_end}
{synopt :{opt plot}}produce a scatter plot of cluster summaries{p_end}
{synopt: {cmdab:sav:ing(}{it:{help filename}}[{cmd:, replace}]{cmd:)}}save the cluster-level dataset in {it:filename}{cmd:.dta}. {p_end}
{synopt :{opth l:evel(#)}}set the level for confidence intervals; default is 95%{p_end}
{synoptline}
{p 4 6 2}{it:indepvars} may not contain interactions{p_end}
{p 4 6 2}*these options are required{p_end}
{p2colreset}{...}

{synoptset 30}{...}
{marker effspec}{...}
{synopthdr :effect}
{synoptline}
{synopt :{opt rr}}risk ratio{p_end}
{synopt :{opt rd}}risk difference{p_end}
{synopt :{opt rater}}rate ratio{p_end}
{synopt :{opt rated}}rate difference{p_end}
{synopt :{opt md}}mean difference{p_end}
{synoptline}

{marker description}{...}
{title:Description}
{pstd}
{cmd:clan} performs cluster-level analysis of data from a cluster randomised trial.
The method follows a two-step procedure. In the first step, cluster summaries are
produced. For a binary outcome, these are simple cluster proportions; for a
continuous outcome, these are cluster means; for a time-to-event outcome these
are rates. If any independent variables are included, am appropriate regression
model (logistic, linear, or poisson) is run {it:without} the arm variable. The
residuals are then summarised by cluster (and strata, if specified).

{pstd}
In the second stage, a linear regression is used to compare the cluster summaries
between the two treatment arms. The stratificaton factor will also be included
in this second stage, if it is specified.

{pstd}
Degrees of freedom are calculated from the number of clusters and then 
penalising by: one to account for the treatment variable; one fewer than the
number of stratification levels; and one for each cluster-level variable
included in the first stage regression.

{pstd}
The data in memory will not be altered by this command.



{marker options}{...}
{title:Options}

{phang}
{opth arm(varname)} is the variable which identifies the two trial arms.
It must be coded 0/1.

{phang}
{opth clus:ter(varname)} is the variable which describes the clusters.
It must be a numeric variable

{phang}
{opt eff:ect} specifies which measure of effect you wish to calculate. If rr or 
rater are specified the confidence interval will be calculated on the log scale
and the estimate will be the geometric mean of the cluster summaries. If any
cluster has zero events, 0.5 will be added to all cluster totals to allow
logarhythms to be taken.

{phang}
{opth str:ata(varname)} is the variable which identifies the stratification used
in the trial. Only one stratification factor is permitted. It must be a numeric
variable.

{phang}
{opth fup:time(varname)} is the variable which gives the length of time each 
participant was in the study; this is necessary to calculate time-to-event
when either rate differences or risks are to be calculated.

{phang}
{opt plot} asks {cmd:clan} to produce a scatter plot of the cluster summaries 
used to produce the effect measure. For adjusted analyses these wil be summaries 
of residual values, and hence will not have a direct interpretation.

{phang}
{opt l:evel(#)} set confidence level; default is {cmd:level(95)}



{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse mkvtrial, clear}{p_end}

{pstd}Analyse trial effect on the knowledge of HIV; estimate risk ratio{p_end}
{phang2}{cmd:. clan know, arm(arm) clus(community) effect(rr)}{p_end}

{pstd}Adjust for the effect of age{p_end}
{phang2}{cmd:. clan know i.agegp, arm(arm) clus(community) effect(rd) plot}{p_end}

{pstd}Also include a stratification factor, and produce 99% confidence intervals{p_end}
{phang2}{cmd:. clan know i.agegp, arm(arm) clus(community) strata(stratum) effect(rd) level(99)}{p_end}

{pstd}Calculate risk difference instead, and plot cluster summaries{p_end}
{phang2}{cmd:. clan know, arm(arm) clus(community) effect(rd) plot}{p_end}

{pstd}Note that when an adjusted model is run, the cluster summaries are not interpretable{p_end}
{phang2}{cmd:. clan know i.agegp, arm(arm) clus(community) effect(rd) plot}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:clan} stores the following in {cmd:e()}:

{synoptset 18 tabbed}{...}
{p2col 5 20 20 4: Scalars}{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(p)}}p-value{p_end}
{synopt:{cmd:e(lb)}}lower bound of confidence interval{p_end}
{synopt:{cmd:e(lb)}}upper bound of confidence interval{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(N)}}number of clusters{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:clan}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector from the regression in the second stage{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{p2colreset}{...}

{marker references}{...}
{title:References}
{phang}
Richard J Hayes and Lawrence H Moulton. Cluster Randomised Trials;
Chapman and Hall/CRC; Second edition, 2017; ISBN 9781498728225

{phang}
RJ Hayes, S Bennett. Simple sample size calculation for cluster-randomized trials; 
IJE 1999; 28:2:319-326 doi: 10.1093/ije/28.2.319

{phang}
S Bennett, T Parpia, R Hayes, S Cousens. Methods for the analysis of incidence 
rates in cluster randomized trials; IJE 2002; 31:4:839-846 doi: 10.1093/ije/31.4.839

{phang}

{marker Authors}{...}
{title:Authors}
Stephen Nash, Jennifer Thompson
London School of Hygiene and Tropical Medicine
London, UK
Jennifer.Thompson@lshtm.ac.uk
