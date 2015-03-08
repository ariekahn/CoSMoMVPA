function test_suite=test_meeg_io()
    initTestSuite;


function test_meeg_dataset()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_meeg_dataset(varargin{:}),'');

    dimords=get_dimords();
    n=numel(dimords);
    for k=1:n
        dimord=dimords{k};
        [ft,fdim,data_label]=generate_ft_struct(dimord);
        ds=cosmo_meeg_dataset(ft);
        assertEqual(ds.a.fdim,fdim);

        [nsamples,nfeatures]=size(ds.samples);

        % check feature sizes
        fdim_sizes=cellfun(@numel,fdim.values);
        assertEqual(prod(fdim_sizes),nfeatures);

        % check sample size
        data=ft.(data_label);
        data_size=size(data);
        has_rpt=nsamples>1;
        if has_rpt
            assertEqual(data_size(2:end)',fdim_sizes);
        else
            assertEqual(data_size',fdim_sizes);
        end

        assertAlmostEqual(data(:),ds.samples(:));

        ds2=cosmo_slice(ds,randperm(nfeatures),2);
        ft2=cosmo_map2meeg(ds2);

        if isfield(ft,'cfg')
            ft=rmfield(ft,'cfg');
        end

        assertEqual(ft,ft2);

        % wrong size trialinfo should not store trialinfo
        assertTrue(isfield(ds2.sa,'trialinfo'));
        ft.trialinfo=[1;2];
        ds3=cosmo_meeg_dataset(ft);
        assertFalse(isfield(ds3.sa,'trialinfo'));
    end

    aet(struct());
    aet(struct('avg',1));
    aet(struct('avg',1,'dimord','rpt_foo'));


function test_synthetic_meeg_dataset()
    combis=cosmo_cartprod({{'timelock','timefreq','source'},...
                            {'tiny','small','normal','big','huge'}});
    for k=1:size(combis,1)
        ds=cosmo_synthetic_dataset('type',combis{k,1},...
                                        'size',combis{k,2});

        ft=cosmo_map2meeg(ds);
        ds2=cosmo_meeg_dataset(ft);
        assertEqual(ds.samples,ds2.samples);
        assertEqual(ds.fa,ds2.fa);
        assertEqual(ds.a.meeg.samples_field,ds2.a.meeg.samples_field);
    end



function dimords=get_dimords()
    dimords={   'chan_time',...
                'rpt_chan_time'...
                'chan_freq',...
                'rpt_chan_freq',...
                'chan_freq_time',...
                'rpt_chan_freq_time',...
                };

function [ft,fdim,data_label]=generate_ft_struct(dimord)
    seed=1;

    fdim=struct();
    fdim.values=cell(3,1);
    fdim.labels=cell(3,1);

    ft=struct();
    ft.dimord=dimord;

    dims=cosmo_strsplit(dimord,'_');
    ndim=numel(dims);
    sizes=[3 4 5 6];

    chan_values={'MEG0113' 'MEG0112' 'MEG0111' 'MEG0122'...
                    'MEG0123' 'MEG0121' 'MEG0132'};
    freq_values=(2:2:24);
    time_values=(-1:.1:2);

    data_label='avg';
    ntrials=1;
    nkeep=0;

    for k=1:ndim
        idxs=1:sizes(k);
        switch dims{k}
            case 'rpt'
                data_label='trial';
                ntrials=numel(idxs);

            case 'chan'
                ft.label=chan_values(idxs);
                nkeep=nkeep+1;
                fdim.values{nkeep}=ft.label;
                fdim.labels{nkeep}='chan';

            case 'freq'
                ft.freq=freq_values(idxs);
                data_label='powspctrm';
                nkeep=nkeep+1;
                fdim.values{nkeep}=ft.freq;
                fdim.labels{nkeep}='freq';

            case 'time'
                ft.time=time_values(idxs);
                nkeep=nkeep+1;
                fdim.values{nkeep}=ft.time;
                fdim.labels{nkeep}='time';

        end
    end

    fdim.values=fdim.values(1:nkeep);
    fdim.labels=fdim.labels(1:nkeep);

    keep_sizes=sizes(1:k);
    ft.(data_label)=norminv(cosmo_rand(keep_sizes,'seed',seed));
    ft.cfg=struct();
    ft.trialinfo=[(1:ntrials);(ntrials:-1:1)]';

