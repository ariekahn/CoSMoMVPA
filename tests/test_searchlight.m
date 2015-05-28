function test_suite = test_searchlight
    initTestSuite;


function test_searchlight_

    ds=cosmo_synthetic_dataset('size','normal');
    m=any(abs(ds.samples)>3,1);
    ds=cosmo_dim_slice(ds,~m,2);

    measure=@(x,a) cosmo_structjoin('samples',size(x.samples,2));
    nh=cosmo_spherical_neighborhood(ds,'radius',2,'progress',0);

    m=cosmo_searchlight(ds,nh,measure,'progress',false);

    assertEqual(m.samples,[8 12 10 9 12 10 16 13 12 17 14 15 ...
                            13 11 15 14 10 9 14 11 5 7 6 7]);
    assertEqual(m.fa.i,ds.fa.i);
    assertEqual(m.fa.j,ds.fa.j);
    assertEqual(m.fa.k,ds.fa.k);
    assertEqual(m.a,ds.a);

    nh2=cosmo_spherical_neighborhood(ds,'count',17,'progress',0);
    m=cosmo_searchlight(ds,nh2,measure,'progress',0);
    assertEqual(m.samples,[17 17 17 17 17 17 17 17 17 17 18 16 ...
                                17 17 16 15 17 17 17 17 17 17 17 17]);


    measure=@cosmo_correlation_measure;

    nh3=cosmo_spherical_neighborhood(ds,'radius',2,...
                                cosmo_structjoin('progress',0));
    m=cosmo_searchlight(ds, nh3, measure,...
                            'center_ids',[4 21],'progress',0);

    assertVectorsAlmostEqual(m.samples, [0.9742,-.0273]...
                                        ,'relative',.001);
    assertEqual(m.fa.i,[1 1]);
    assertEqual(m.fa.j,[2 1]);
    assertEqual(m.fa.k,[1 5]);

    sa=struct();
    sa.time=(1:6)';
    sdim=struct();
    sdim.values={10:15};
    sdim.labels={'time'};

    nh4=cosmo_spherical_neighborhood(ds,'radius',0);
    measure2=@(x,opt)cosmo_structjoin('samples',mean(x.samples,2),...
                                       'sa',sa,...
                                       'a',cosmo_structjoin('sdim',sdim));
    m2=cosmo_searchlight(ds,nh4,measure2,'progress',false);
    assertEqual(m2.sa,sa);
    assertEqual(m2.a.sdim,sdim);
    assertElementsAlmostEqual(m2.samples,ds.samples);



function test_searchlight_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_searchlight(varargin{:},...
                            'progress',0),'');
    ds=cosmo_synthetic_dataset();
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
    measure=@(x,opt)cosmo_structjoin('samples',mean(x.samples,2));

    aet(struct,nh,measure);
    aet(ds,ds,measure);
    aet(ds,measure,nh);

    measure_bad=@(x,opt)cosmo_structjoin('samples',mean(x.samples,1));
    aet(ds,nh,measure_bad);



