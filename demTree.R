library(foreach)

source('./badges.R')


# 
# Calculate information gain of the feature represented by
# the column coln of the dataset matrix
# 
multiCalcGain <- function(set,coln){
  dem <- nrow(set)  
  ps <- foreach(i=unique(set[,1]),.combine=c) %do% {
    noom <- sum(set[,1]==i)
    p <- noom / dem
  }

  baseEntrop <- multiInfoEntrop(ps)
  
  retVal <- foreach(val = unique(set[,coln]),.combine = sum) %do% {
    dem.s <- sum(set[,coln]==val)
    s.v <- set[set[,coln]==val,,drop=F]
    ps.v <- foreach(i=unique(s.v[,1]),.combine=c) %do% {
      noom.s <- sum(s.v[,1]==i)
      p.s <- noom.s / dem.s
      
    }

    retVal <- sum(set[,coln]== val)/dem * multiInfoEntrop(ps.v)
    retVal
  }  
  baseEntrop - retVal
}

#
# Calculate information entropy
#
multiInfoEntrop <- function(labs){
  foreach(i=labs,.combine=sum) %do% {
    if(i==0) 0 else -i*log(i)/log(2)
  }
}



#
# Note: The first column is assumed to be the observation label
#
chooseAttribute <- function(set,usedAttributes){
  availableAttributes <- setdiff(1:ncol(set),usedAttributes)
  
  gains <- foreach(att = availableAttributes,.combine = c) %do% {
    multiCalcGain(set,att)
  }
  
  availableAttributes[which.max(gains)]
}

#
#
#
buildNode <- function(coln,childFun=list(function(obs){0},function(obs){1})){
  # Return a function that takes an observation (vector of booleans represented as 0/1)
  # and returns one of two functions of the observation
  function(obs){childFun[[obs[coln]+1]](obs)}
}


becomeTree <- function(set,usedAttributes=c(1)){
  
  if(length(unique(set[,1]))==1){
    #
    # If the data contains only a single label, return a lambda
    # that predicts that label for any input.
    #
    retVal <- function(obs){set[[1,1]]}
  } else {
    #
    # If mutiple lables are present in data, pick the one with
    # the greatest information gain
    #
    coln <- chooseAttribute(set,usedAttributes)
#     print("used attributes:")
#     print(usedAttributes)
#     print("next attribute")
#     print(coln)
#     print(letters[coln-1-28])

    seg <- set[,coln]==0

    #
    # recurse down the tree
    #
    f0 <- becomeTree(subset(set, seg),usedAttributes = c(usedAttributes,coln))
    f1 <- becomeTree(subset(set,!seg),usedAttributes = c(usedAttributes,coln))
    #
    # return a lambda that predicts a label based on the column coln
    #
    retVal <- buildNode(coln,childFun = c(f0,f1))
  }
  retVal
}



testTree <- function(){
  badges <- importBadgeData()
  nSpar <- makeAllMax(badgeData = badges)
  classifier <- becomeTree(nSpar[1:200,1:56])
  preds <- foreach(i = 201:nrow(nSpar),.combine=c) %do% {
    classifier(nSpar[i,])
  }
  comps <- data.frame(actual=nSpar[201:nrow(nSpar),1],preds=preds)
  xtabs(~.,comps)
}


