#Delete file tool for JunkFile.

#Allow: mov, img(by mov)
#Deny: And others.

#全ファイルリスト
@all_filelist = Array.new()
#ジャンクファイル
@junk_filelist = Array.new()


@filelist = {all:[], mov:[], img:[], junk:[]}

#許可対象, ファイルサイズはバイト単位で記入
#100000000byte = 100MB
@allow_file_conditions = {mov: {ext: %W{mp4 mov avi mkv}, min_filesize: 100000000},
                         img: {ext: %W{jpg jpeg png gif}}}
puts "@allow_file_conditions: #{@allow_file_conditions}"


#捜査対象ディレクトリの指定
if ARGV[0].nil?
  puts "CommandLineVar Err"
  exit
end
@target_directory = ARGV[0]


puts "--------------------------------"
puts "@target_directory: #{@target_directory}"




#@target_directory配下の全ファイル操作
Dir.glob("#{@target_directory}/**/*") do |item|
  @filelist[:all] << {filepath: item, extname: File.extname(item).delete('.'), size: File.size(item), delete: false} if FileTest.file?(item)
end

#ファイルリスト格納
@filelist[:all].each do |item|
  #mov
  if @allow_file_conditions[:mov][:ext].include?(item[:extname])
    @filelist[:mov] << item
  #img
  elsif @allow_file_conditions[:img][:ext].include?(item[:extname])
    @filelist[:img] << item
  #junkfile
  else
    @filelist[:junk] << item
  end
end



%W{mov img junk}.each do |key|
  puts "@filelist[:#{key}]:"
  @filelist[key.to_sym].each {|item| p item}
end
puts "-------------------------------------------"

#mov 削除判定
@filelist[:mov].each_with_index do |item, idx|
  #指定ファイルサイズ以下のものは削除
  @filelist[:mov][idx][:delete] = true if item[:size] < @allow_file_conditions[:mov][:min_filesize]
end

#img 削除判定
@filelist[:img].each_with_index do |item, idx|
  #2バイト文字を含むもの
  if File.basename(item[:filepath]) =~ /[^ -~｡-ﾟ]/
    @filelist[:img][idx][:delete] = true
  end
end

%W{mov img junk}.each do |key|
  puts "@filelist[:#{key}]:"
  @filelist[key.to_sym].each do |item|
    p item if item[:delete] == false
  end
end
