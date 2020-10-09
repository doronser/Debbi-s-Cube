% function ENVIREAD_NEW
% [data, bands_2_read, data_type, interleave]=enviread(file_to_open)
% This function opens datacube binary files in BSQ, BIP, BIL formats.
% file_to_open is the datacube name, including extension. the datacube should have a header 
% file with the same name and with ".hdr" extension.
% The function can open a single band, selected bands, or the full datacube. 
%
% Modified by Ori Raviv, 2003


function [data, bands_2_read, data_type, interleave]=enviread_new(file_to_open);
num_bytes=[1 2 4 4];
if (file_to_open(length(file_to_open)-2:length(file_to_open))=='hdr')%check last 3 chars
  disp('Please use the data file name, including extension (if exists)');
  return
else %if the file has an extension other than hdr
    if  file_to_open(length(file_to_open)-3)=='.'
        temp_file=zeros([1 length(file_to_open)]);
        temp_file=char(temp_file);
        temp_file(1:length(temp_file))=file_to_open(1:length(temp_file));
        temp_file(length(temp_file)-2:length(temp_file))='hdr';
        [samples lines bands data_type interleave]=get_header_param(temp_file);
        clear temp_file;
    else %if the file has no extension
        temp_file=zeros([1 length(file_to_open)+4]);
        temp_file=char(temp_file);
        temp_file(1:length(file_to_open))=file_to_open(1:length(file_to_open));
        temp_file(length(temp_file)-3:length(temp_file))='.hdr'; %add extension .hdr
       [samples lines bands data_type interleave]=get_header_param(temp_file)
        clear temp_file;
    end
end

v=[4:4:100 116:4:152 168:4:212]; % selective ENVI spectrum 
%v=[4:4:40 84:4:100 116:4:152 168:4:212]; disp('VVVVVVVVVV No vegi')% for testing, no vegetation band
%v=v([3:3:45]); % for testing

% bands_2_read=input('Please enter vector of bands to read [b1 b2 ..], v for ENVI selected spectrum, or 0 for all bands - ')
bands_2_read=0
if bands_2_read==0
  bands_2_read=[1:bands]
end
switch data_type
case 1
    type='uint8'; % 8 bits
case 2
    type='short'; %signed integer,  16 bits 
case 3
    type='ulong';
case 4
    type='float';
end
fid=fopen(file_to_open,'r');
switch interleave
case 'bsq' % ************* Band Sequential (BSQ)
    w=waitbar(0,'Reading datacube, BSQ format');
    waitbar(0,w);
    j=1; % Index for data if not all datacube is read.
    for i=bands_2_read
        waitbar(i/max(bands_2_read),w)
        indx=samples*lines*(i-1)*num_bytes(data_type);
        status=fseek(fid,indx,'bof');
        [help_mat count]=fread(fid,[samples lines],type);
        data(:,:,j)=help_mat(:,:)';
        j=j+1;
    end
    close(w)
    disp('NOTE : The matrix form is lines(rows)*samples(columns)*bands(spectrum)');
case 'bip' %Band Interleaved by Pixel
  j=1;% Index for data if not all datacube is read.
  for i=bands_2_read  %:bands
    i
    fseek(fid,0,-1);
    [temp count]=fread(fid,i-1,type);
    bytes_to_skip=num_bytes(data_type)*(bands-1);
    [help_mat count]=fread(fid,[samples lines],type,bytes_to_skip);
    data(:,:,j)=help_mat(:,:)';
    j=j+1;
  end
  disp('NOTE : The matrix form is lines(rows)*samples(columns)*bands(spectrum)');
% ******************* new, Ori ******************************************    
case 'bil' %Band Interleaved by Line
  disp('opening all bands!')
  fseek(fid,0,-1); %rewind
  for j=1:lines
    for i=1:bands
      [help_mat count]=fread(fid,samples,type);
      data(j,:,i)=help_mat(:)';
    end
  end
end
fclose(fid);

        
