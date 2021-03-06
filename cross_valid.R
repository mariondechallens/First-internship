.libPaths(c("C:/Marion/Rstudio/packages_install",.libPaths()))
library(leaps)
library(ISLR)
source(file = "C:/Marion/T2S_LabStatistics/MOTI_NTS_analysis/MOTI_regressions/moti_reg_facto.R")  ##for functions

##trying backward and forward elimination with cross-validation
data<-read.table("C:/Marion/T2S_LabStatistics/SOA/total_cleaned_data.csv",header=TRUE,sep=";", dec=",")
table<-na.omit(regression(data,pval)$dataframe[,-1]) #on enl�ve la colonne date

predictFUN<-function(object,newdata,id){   ##fonction de prediction sur un nouveau jeu de donn�es
  form<-as.formula(object$call[[2]])
  mat<-model.matrix(form,newdata)
  coefi<-coef(object,id=id)
  mat[,names(coefi)]%*%coefi
}

# On construit manuellement une cross validation en divisant les donn�es en K �chantillons de taille �gale
# Pour chacun des K-1 subsets, on va produire n meilleurs mod�les (taille 1 � n), un pour chaque complexit�
# On calcule la MSE des  mod�les sur chacun des 10 subsets
# On moyenne cette MSE pour chacun des  mod�les
nbsets<-10
nbvar<-25

for (elimination in c("forward","backward")){
  set.seed(11)
  folds<-sample(rep(1:nbsets,length=nrow(table)))  ## creation des K subsets (folds)
  RSS_training<-matrix(NA,nbsets,nbvar)
  R2_matrix<-matrix(NA,nbsets,nbvar)
  R2_adj_matrix<-matrix(NA,nbsets,nbvar)
  for(k in 1:nbsets){
    models_training_cv<-regsubsets(Value...NTS~.,data=table[folds!=k,],
                                  nvmax=nbvar,method=elimination,really.big = T)  ##choosing among a high number of variables

    for(i in 1:nbvar){  ##creation des n mod�les sur chacun des des K subsets
      pred<-predictFUN(models_training_cv,table[folds==k,],id=i)
      RSS_training[k,i]<-mean((table$Value...NTS[folds==k]-pred)^2)
      R2_matrix[k,i]<-summary(models_training_cv)$rsq[i]
      R2_adj_matrix[k,i]<-summary(models_training_cv)$adjr2[i]
      
    }
  }
  
  RMSE_cv<-sqrt(apply(RSS_training,2,mean))  ##racine de la moyenne des erreurs au carr�
  plot(RMSE_cv,pch=19,type='b',main=paste0("RMSE par complexit� pour ",elimination),xlab="Nb de variables (complexit� du mod�le)")
  
  R2<-apply(R2_matrix,2,mean)
  R2_adj<-apply(R2_adj_matrix,2,mean)
  plot(R2,pch=19,type="b",main=paste0("R� and R� adjusted for ",elimination),xlab="Nb de variables",col="blue")
  points(R2_adj,pch=19,col="green")
  legend("topleft",legend=c("R�","R� adjusted"),col=c("blue","green"),pch=19)
}



