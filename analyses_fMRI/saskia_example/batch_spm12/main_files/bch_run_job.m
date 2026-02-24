function [cfg] = bch_run_job(cfg)

job = cfg.jobname;
cfg_util('run',job);