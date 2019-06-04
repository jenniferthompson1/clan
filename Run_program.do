/*

Do file to run the Hayes program

Stephen Nash
16th May 2019

*/
cd "C:\Users\EIDESNAS\Dropbox\Work\lshtm\Methods\Hayes and Bennett method"
use "Datasets\mkvtrial" , clear

** Risk ratio
hayes_crt know , arms(arm) strat(stratum) clus(community) effect(rr)
hayes_crt know agegp ethnicgp, arms(arm) strat(stratum) clus(community) adj effect(rr)

** Risk difference
hayes_crt know , arms(arm) strat(stratum) clus(community) effect(rd)
hayes_crt know agegp ethnicgp, arms(arm) strat(stratum) clus(community) adj effect(rs)

** Poisson
hayes_crt know , arms(arm) strat(stratum) clus(community) effect(poisson)



** Means
hayes_crt lifepart , arms(arm) strat(stratum) clus(community) effect(means)
hayes_crt lifepart agegp , arms(arm) strat(stratum) clus(community) effect(means) adjus




