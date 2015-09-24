library(foreach)
library(glmnet)

source('./dataSourcer.R')
# http://svivek.com/teaching/machine-learning/fall2015/data/badges.txt

checkNameMax <- function(nameMax,nameList){
  sum(apply(nameMax,c(1),sum) - nchar(nameList)) == 0
}

makeAllMax <- function(badgeData){
  #
  # Make one big matrix that has the binary vectors from all names
  #
  allMax <- (lapply(badgeData[,2:4],FUN=nameToMax))
  maxLabs <- as.numeric(badgeData$label=='+')
  newMax <- cbind(maxLabs,
                  foreach(i=allMax,.combine = cbind) %do% {i})
  newMax
}

trainLogistic <- function(nSpar, alpha=1,pctTrain=0.5,lambdaRatio=0.05){
  #
  # Train a logistic model on the binary vector representation of the names
  #
  
  #
  # Sample the records and create holdout
  #
  trainSet <- runif(n=nrow(nSpar),min=0,max=1) < pctTrain
  testSet <- ! trainSet
  
  #
  # glmnet implements penalized regression models.  The penalty is a linear combination
  # of the LASSO and Ridge penalties (blended via the 'alpha' parameter), and the
  # optimal penalty factor is chosen by cross-validation (the factor that gives least
  # mean x-val error is selected as lambda.min, and the the factor that gives x-val error
  # within 1sd of lambda.min is lambda.1se).  The .min value will build a more complex model
  # than .1se because the penalty factor is smaller.
  #
  # family='binomial' is used to tell glmnet that we want logistic regression instead of linear
  #
  glmod <- cv.glmnet(nSpar[trainSet,-1],
                     nSpar[trainSet,1],
                     family='binomial',
                     alpha=alpha,nlambda=100,lambda.min.ratio = lambdaRatio)

  list(trainingSet=trainSet,testSet=testSet,model=glmod)
  
}

checkModel <- function(nSpar,testSet, model, lambda){
  #
  # Check how well the model works on the hold-out sample
  #
  resp <- data.frame(x=predict.cv.glmnet(model,
                                         nSpar[testSet,-1],
                                         s=lambda,type='response'))
  
  #
  # Plot the distribution of predicted probabilites (we would like
  # a large gap between high and low, as this indicates more confidence)
  #
  print(ggplot(data=resp) + stat_density(aes(x=X1),adjust=0.05))
  
  #
  # Compare the predicted and actual labels on the holdout set
  #
  xtabs(~.,data.frame(x=resp[,1]>0.5,y=nSpar[testSet,1]))
  
}

nzModelBeta <- function(model,lambda){
  #
  # Let's take a closer look at the predictors chosen by glmnet
  #
  albet <- c(letters,'-','.')
  lambdaIdx <- 98
  lambdaIdx <- which(model$lambda == lambda)
  betaIdx <- which(model$glmnet.fit$beta[,lambdaIdx]!=0)
  numChar <- (nrow(model$glmnet.fit$beta))%/%length(albet)
  
  dfnz <- data.frame(val=matrix(model$glmnet.fit$beta[betaIdx,lambdaIdx]))
  #
  # Build labels for each binary vector in the form AN, where A is a letter
  # from the alphabet and N is a number inidcating the position of the character
  # within the name.
  #
  charList <- rep(albet,numChar)
  charList <- paste0(charList,(1:length(charList)-1)%/%length(albet))
  dfnz <- cbind(let=charList[betaIdx],dfnz)
  dfnz

}


testBadges <- function(alpha=1,pctTrain=0.65,lambdaRatio=0.05){
  badges <- importBadgeData()
  nSpar <- makeAllMax(badgeData = badges)
  glmeta <- trainLogistic(nSpar = nSpar,alpha=alpha,pctTrain=pctTrain,lambdaRatio = lambdaRatio)
  print(checkModel(nSpar,glmeta$testSet,glmeta$model,glmeta$model$lambda.min))
  nzModelBeta(glmeta$model,glmeta$model$lambda.min)
}


