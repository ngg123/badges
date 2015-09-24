library(foreach)

source('./badges.R')


#
# Set is assumed to be a {sparse} matrix with one observation per row
#
# 
calcGain <- function(set,coln){
  dem <- nrow(set)  
  noom <- sum(set[,1])
  p <- noom / dem
  n <- (dem - noom) / dem
  baseEntrop <- infoEntrop(n,p)
  
  retVal <- foreach(val = unique(set[,coln]),.combine = sum) %do% {
    dem.s <- sum(set[,coln]==val)
    s.v <- matrix(set[set[,coln]==val,],nrow=dem.s)
    noom.s <- sum(s.v[,1])
    p.s <- noom.s / dem.s
    n.s <- (dem.s - noom.s)/dem.s
    retVal <- sum(set[,coln]== val)/dem * infoEntrop(n.s,p.s)
    retVal
  }  
  baseEntrop - retVal
}

infoEntrop <- function(n,p){
  # Thar logarithm twernt takin a like'n to them zaros
  if(any(c(n,p)==0)){0} else {
    -n*log(n)/log(2) - p*log(p)/log(2)
  }
}


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
# TODO: generalize to non-binary trees
#
buildNode <- function(coln,childFun=list(function(obs){0},function(obs){1})){
  # Return a function that takes an observation (vector of booleans represented as 0/1)
  # and returns one of two functions of the observation
  function(obs){childFun[[obs[coln]+1]](obs)}
}

becomeTree <- function(set,usedAttributes=c(1)){
  
  if(length(unique(set[,1]))==1){
    retVal <- function(obs){set[[1,1]]}
  } else {
    coln <- chooseAttribute(set,usedAttributes)
#     print("used attributes:")
#     print(usedAttributes)
#     print("next attribute")
#     print(coln)
#     print(letters[coln-1-28])

    seg <- set[,coln]==0
    
    f0 <- becomeTree(subset(set, seg),usedAttributes = c(usedAttributes,coln))
    f1 <- becomeTree(subset(set,!seg),usedAttributes = c(usedAttributes,coln))
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


