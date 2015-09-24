# badges

__UPDATE: Now with decision trees and k-nearest neighbors!__


I've slightly adjusted the file structure:

* dataSourcer.R: most of the data import functions are here now
* badges.R: mostly Elastic Net logistic regression functions for badges data
* demTree.R: mostly functions for implementing an ID3 decision tree
* k-nearest.R: mostly functions for implementing k-nearest neighbors, but also has cross-validation and validation functions.

TODO: 
* further refactor functions into appropriate files
* becomeTree() doesn't /quite/ support multiple feature levels yet (fix this)




#### Toy Machine Learning on Badges data from a 1994 Computational Learning Theory conference.

Per the slides at http://svivek.com/teaching/machine-learning/fall2015/lectures/01-intro.html , attendees at a ML conference were given badges labeled with '+' and '-' and instructed to learn the function used to generate the labels.  Attendees were given the hint that the label was a function of only the name on the badge.

The function is given in the slides for the second lecture of the ML couse linked above, but we are going to pretend that we haven't seen it.  Further, we are going to try to build a classifier that will make correct predictions without giving it a set of features that are too obvious.

Spoilers below!

The basic approach here is to treat each character in a name (which consists of up to 4 parts, using the letters a-z, as well as the dash ('-') and dot ('.')) as a factor.  The factors levels are converted to boolean vectors (one vector for each level).  Names contain less than 34 characters, and the alphabet has 28 levels, giving us a feature matrix with 952 dimensions (and only 294 observations!).  

## Learning with Regression
### (See below for an updated version using ID3 trees)

We will use a very simple linear classifier for this implementation: logistic regression.  The simple logistic regression (as found in R's glm package) will not work very well because our data set has so many dimensions--with 952 degrees of freedom and only 294 observations, it is very easy to overfit.  Instead, we will use penalized linear regression from the glmnet package, which allow a linear combination of the Ridge (L2) penalty and LASSO (L1) penalty.

As those who are familiar with Elastic Net might expect, the regression works better with heavier weight on the LASSO penalty because we primarilly want to eliminate redundant degrees of freedom.

Running the test function (after sourcing badges.R) gives this as a typical result:
> testBadges(alpha=1)
 
       |  0 | 1
 ------|----|----
  FALSE| 19 | 0
  TRUE |  0 |73
  
  
coef| let |        val
---|----|-------------
1 |  a0 | -0.15109255
2 |  e0 | -0.04976486
3 |  a1 |  **9.34296388**
4 |  d1 | -0.08895683
5 |  e1 |  **8.71469205**
6 |  h1 | -0.86992335
7 |  i1 |  **8.92423989**
8 |  l1 | -0.27893943
9 |  n1 | -0.13082222
10 |  o1 |  **9.07778198**
11 |  r1 | -1.01242497
12 |  t1 | -0.70022769
13 |  u1 |  **8.23083841**
14 |  y1 | -0.13046249
15 |  .1 | -0.27931667
16 |  a2 | -0.13896379
17 |  e2 | -0.03790973


The crosstabulation shows 19 true negatives, 73 true positives, and no false positives or false negatives in the holdout data set (approxiately 35% of the original set).  [Note: There are sometimes a few false positives, depending on which names are sampled for the regression.  More below.]  Equally interesting is the sent of features the regression chose for predictions.  

All features have weakly negative coefficients, *EXCEPT* for a,e,i,o, and u in the second character of the first name. The vowels have strongly positive coefficients.  Based on this, we can surmise that the 'true' function is that the label '+' is placed on badges when the second letter of the attendee's first name is a vowel, and '-' is placed when the second letter is a consonant.  

It's also interesting to note that there are weekly negative coefficients for the first and third letters of the first name, which suggests that the regression has inadvertently discovered that the first names of people who attend Machine Learning confereneces in the mid 1990's are unlikely to have 'a' or 'e' for the first or third letter when the second letter is a vowel.

One weakness of this approach is that the classifier does not learn that 'vowels' are a feature.  As there are only 11 names with u as the second letter of the first name (compared to 85,28,37, and 49 for a,e,i and o, respectively), any training set without a second-letter u will not learn to associate u with the '+' label--in fact it will usually try to classify on consonants, by giving them larger negative coefficients and the vowels smaller positive coefficients.

## Learning with ID3 and kNN

Homework #1 for C6350 Fall 2015 asks to build two classifiers: a k-nearest-neighbors classifier and a decision tree classifier using the ID3 algorithm.

ID3 and kNN classifiers have been added to the repo, and work much better than logistic regression on both badges data and a tic-tac-toe dataset prepared by Dr. Vivek S.  Both ID3 and kNN achieve close to 100% correct classification in cross-validation and on a separate test dataset.  

The tree classifier takes a matrix of features and labels (the first column of the matrix is assumed to be the label and all other columns are features).  The becomeTree() function uses recursion and anonymous functions to build a decision tree classifier (there is no separate data structure to hold the decisions at each level, which does have the disadvantage of making it's decisions somewhat opaque).

The kNN classifier uses the hamming distance to compare points.

