"""
Bayesian model selection script

Based on SPM's bms function
Converted to Python by Mingqian Guo
"""

import numpy as np
import pandas as pd
from scipy import stats
from scipy.special import log_softmax, softmax, psi, gammaln
from scipy.stats import beta, gamma
eps_ = 1e-16

## Bayesian model selection

def bms(me, tol=1e-4):
    """
    Args: 
        me: matrix [subject number x model number ] for log-model evidence
    
    Outputs:
        BMS result: dict
            -alpha: [1, Nm] posterior of the model probability
            -p_m1D: [nSub, Nm] posterior of the model 
                     assigned to the subject data p(m|D)
            -E_r1D: [nSub, Nm] expectation of E[p(r|D)]
            -xp:    [Nm,] exceedance probabilities
            -bor:   [1] Bayesian Omnibus Risk, the probability
                    of choosing null hypothesis: model frequencies are equal
            -pxp:   [Nm,] protected exceedance probabilities
    """
    m_n = me.shape[1] ## model number
    alpha0, alpha = np.ones(m_n), np.ones(m_n) ## prior and posterior of model parameter

    while True:
        
        prev = alpha.copy() # store last iteration alpha
        # compute the posterior: Nsub x Nm
        log_u = me + psi(alpha) - psi(alpha.sum())
        u = np.exp(log_u - log_u.max(1, keepdims=True)) # the max trick 
        p_m1D = u / u.sum(1, keepdims=True)
        beta = p_m1D.sum(0, keepdims=True) # compute beta
        alpha = alpha0 + beta  # update alpha
        # check convergence 
        if np.linalg.norm(alpha - prev) < tol:
            break 
    
    # get the expected posterior 
    E_r1D = alpha / alpha.sum()
    # get the exeedence probabilities 
    xp = dirchlet_exceedence(alpha)
    ## get the negative free energy
    nfe = FE(me, p_m1D, alpha, alpha0)
    # get the Bayesian Omnibus risk
    bor = calc_BOR(me, p_m1D, alpha, alpha0)
    # model averaging
    pxp=(1-bor)*xp+bor/m_n
    # summerize the result 
    BMS_result = pd.DataFrame({ 'alpha_post': alpha.flatten(), 'xp': xp.flatten(), 'pxp': pxp.flatten(),
                              'nfe':nfe,'bor':bor})

    return BMS_result

def group_bms(me,tol=1e-4):
    """
    between group bayesian model selection
    Args:
        me: list for model evidence
            each element in the list is a matrix [model number x participant number]
    Output:
        Ppe: posteior probability that different group share a same model frequency
    """
    group_num = len(me)
    sum_me = np.concatenate([i for i in me],axis=1)
    fe = bms(sum_me)['nfe'].iloc[1]
    fd = 0
    for n in range(group_num):
        fd += bms(me[n])['nfe']
    return {'Ppe':1/(1+np.exp(fd-fe))}

def dirchlet_exceedence(alpha_post, nSample=1e6):
    '''Sampling from dirchlet to calculate exceedence probability
    Args:
        alpha: [1,Nm] dirchilet distribution parameters
        nSample: number of samples, following Stephan etal.,2009 default = 1e6
    Output: 
    '''
    m_num = alpha_post.shape[1] ## model number
    alpha_post = alpha_post.flatten()

    # sampling 
    r = np.random.dirichlet(alpha_post,int(nSample))
    raw_ep = np.argmax(r,axis=1)
    ep = np.zeros([m_num])
    # calculate ep
    for n in range(m_num):
        ep[n] = np.count_nonzero(raw_ep==n)
    return ep / nSample ## normalized xp

def calc_BOR(lme, p_m1D, alpha_post, alpha0):
    '''Calculate the Bayesian Omnibus Risk
     Args:
        lme: [Nsub, Nm] log model evidence
        p_r1D: [Nsub, Nm] the posterior of each model 
                        assigned to the data
        alpha_post:  [1, Nm] H1: alpha posterior 
        alpha0: [1, Nm] H0: alpha=[1,1,1...]
    Outputs:
        bor: bayesian version of p-value
    '''
    # calculte F0 and F1
    f0 = F0(lme)
    f1 = FE(lme, p_m1D, alpha_post, alpha0)
    bor = 1 / (1+ np.exp(f1-f0))
    return bor 

def F0(lme):
    '''Calculate the negative free energy of H0
    Args:
        lme: [Nsub, Nm] log model evidence
    Outputs:
        f0: negative free energy as an approximation
            of log p(D|H0)
    '''
    Nm = lme.shape[1]
    qm = softmax(lme, axis=1)    
    f0 = (qm * (lme - np.log(Nm) - np.log(qm + eps_))).sum()                                  
    return f0
    
def FE(lme, p_m1D, alpha_post, alpha0):
    '''Calculate the negative free energy of H1
    Args:
        lme: [Nsub, Nm] log model evidence
        p_m1D: [Nsub, Nm] the posterior of each model 
                        assigned to the data
        alpha_post:  [1, Nm] H1: alpha posterior 
        alpha0: [1, Nm] H0: alpha=[1,1,1...]
    Outputs:
        f1: negative free energy as an approximation
            of log p(D|H1)
    '''
    E_log_r = psi(alpha_post) - psi(alpha_post.sum())
    E_log_rmD = (p_m1D*(lme+E_log_r)).sum() + ((alpha0 -1)*E_log_r).sum()\
                + gammaln(alpha0.sum()) - (gammaln(alpha0)).sum()
    Ent_p_r1D = -(p_m1D*np.log(p_m1D + eps_)).sum()
    Ent_alpha  = gammaln(alpha_post).sum() - gammaln(alpha_post.sum()) \
                                        - ((alpha_post-1)*E_log_r).sum()
    f1 = E_log_rmD + Ent_p_r1D + Ent_alpha
    return f1


if __name__ == '__main__':
    print('This is a module and should not be run directly.')