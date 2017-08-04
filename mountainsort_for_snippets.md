# Running Mountainsort on spike snippets

This is applicable if you have saved the filtered waveforms of your spikes (aka “snippets” aka “clips”), rather than continuously recorded broadband data.

## Convert waveforms and event times to mda format

Concatenate the waveforms horizontally with zeros padded in between.
  * For example, if your snippet data is saved in a 4x40xN Matlab array, where:
    * 4 = number of channels (a tetrode)
    *	40 = number of samples in the snippet
    * N = number of events
  * Concatenate with zeros(size(snippet,2)) between snippets such that you end up with a 2D matrix of 4x(2x40xN)
    * The rows must be the channels of the ntrode
    * Zeroes can be any length but should be at least as long as a snippet
    * The padding is important so that when Mountainsort detects events and makes its own clips, there will not be overlap between the waveforms of neighboring spikes!
  * Convert this matrix to mda format using writemda()

Next, make a vector of pseudo event times for Mountainsort to use as the peak timestamps of each event.
  * For each event, find the peak amplitude across all channels of the ntrode.
  * Then find the column index of that peak.
  * In other words, there will be 1 index per event, and this will correspond to the channel with the largest peak (even if the peaks on the other channels fall at slightly different indices). This should be a 1D vector of indices into your 2D matrix of snippets.

To do all of this, look at Mari’s Matlab function [waves2mda](https://bitbucket.org/franklab/trodes2ff_shared/src/d360eaf7bce693cb37b8ad56a89c7d45406d63fa/waves2mda.m?at=develop&fileviewer=file-view-default) as an example.

The following files should be created in a .mda directory:
  * raw.nt[num].mda - the mda of your snippets per ntrode (replace [num] with the ntrode number)
  * event_times.nt[num].mda - the indices of the peak for each event per ntrode

## Run setup javascript
Same as for continuous data - create datasets.txt, pipelines.txt, raw.mda.prv, and params.json. Run in the parent directory above the .mda directory.

## Run Mountainsort 

To sort using your pseudo event times:
  * Manually pass in --prescribed_event_times=/path/to/event_times after the pipeline call.
  * Since each ntrode has its own event_times, you could do this at the command line or each ntrode could have an entry in pipelines.txt.

Optimize the following sorting parameters. You can list these arguments in pipelines.txt:
  * --freq_min and --freq_max should be the bandpass used to filter your snippets during recording. Mountainsort will re-filter the data and you don’t want this to change the waveforms!
  * --detect_sign should match spike detection during recording.  If your data acquisition software triggered on downward-going spikes (extracellular), set --detect_sign=-1.
  * --detect_interval_msec should also match spike detection during recording. Although Mountainsort can detect spikes as close together as 0.33 ms from continuous data, you don’t want it detecting double spikes from your snippets. Try --detect_interval_msec=1.
  * --mask_out_artifacts=true to exclude noise artifacts (can also set the threshold).
  * --clip_size_msec should be the same size or larger than your original clips, but not so large that it encompasses multiple clips.  It is fine to include some zeroes on either side of the clip.

Run sorting
  * Example: 
```bash
kron-run ms2 --prescribed_event_times=/datadir/dataset.mda/event_times.nt13.mda nt13
```

## Curate clusters in mountainview 

Please note:
  * Firing rates and duration given in cluster metrics will be INCORRECT due to the padding.  
  * Autocorrelograms will also be useless--you'll never have anything at zero because you artificially added data points between spikes.
  * Snippets will still get whitened in the sorting process (this is useful!).

For curation, I suggest looking at:
  * Firing events (filtered)
  * Peak amplitude features (filtered)    
  * Discrim histograms (whitened)
  * PCA features (whitened)
  * Amplitude histograms (whitened)
  * Cross correlograms (filtered), only to assess bursting and identify merge candidates 
