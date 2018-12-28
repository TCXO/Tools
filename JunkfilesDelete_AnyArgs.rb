#Delete file tool for JunkFile.
#操作の流れ:
# 1. コマンドライン引数にて操作対象ディレクトリ(複数可)を指定
# 2. 全ファイルリストを取得, mov/img/otherに分類
# 3. 指定要件に該当しないファイルを削除対象に設定、動画を除く対象ファイルを一時保管場所にコピーする
# 4. 一時保管場所にコピーされたファイルを確認(プレビュー)、問題なければ一時保管ファイルおよび実ファイルを削除する

require 'terminal-table'

#全ファイルリスト
@filelist = {all:[], mov:[], img:[], junk:[]}

#許可対象, ファイルサイズはバイト単位で記入
#100000000byte = 100MB
@allow_file_conditions = {mov:   {ext: %W{mp4 mov avi mkv wmv flv mpg asf iso rmvb}, min_filesize: 100000000},
                          img:   {ext: %W{jpg jpeg png gif zip rar 7z}}}
@delete_filename_blacklist = [
"HOTAVXXX,Free Adult Movie, Fastest & Newest Porn Movie Site.jpg",
"最新地址和更多资源.jpg"
]

#捜査対象ディレクトリの指定
if ARGV[0].nil?
  puts "Command-line arguments Err"
  exit
end
@tmp_files_directory = "/Volumes/002/Delete_Previews"
puts "---*Info*----------------------------------------"
puts "@tmp_files_directory: #{@tmp_files_directory}"

@target_directory = ARGV
puts "@target_directory:"
@target_directory.each do |item|
  puts "･#{item}"
end

#@target_directory配下の全ファイル取得, 分類
@target_directory.each do |directory|
  Dir.glob("#{directory}/**/*") do |item|
    #ファイルのみ操作
    next if FileTest.directory?(item)

    #ファイルリスト格納, 全体リスト
    fileinfo = {filepath: item, basename: File.basename(item), extname: File.extname(item).delete('.'), size: File.size(item), delete: false}
    @filelist[:all] << fileinfo

    #ファイルリスト格納, ファイル種別
    #mov
    if @allow_file_conditions[:mov][:ext].include?(/#{File.extname(item).delete('.')}/i)
      @filelist[:mov] << fileinfo
    #img
    elsif @allow_file_conditions[:img][:ext].include?(File.extname(item).delete('.'))
      @filelist[:img] << fileinfo
    #junkfile
    else
      @filelist[:junk] << fileinfo
    end
  end
end


# *削除判定
#mov 削除判定
@filelist[:mov].each_with_index do |item, idx|
  #指定ファイルサイズ以下のものは削除
  @filelist[:mov][idx][:delete] = true if item[:size] < @allow_file_conditions[:mov][:min_filesize]
end

#img 削除判定
@filelist[:img].each_with_index do |item, idx|
  #ファイル名に2バイト文字を含む
  if item[:basename] =~ /[^ -~｡-ﾟ]/
    @filelist[:img][idx][:delete] = true
  end
  #ブラックリスト入り
  if @delete_filename_blacklist.include?(item[:basename])
    @filelist[:img][idx][:delete] = true
  end
end

#junk 削除判定
@filelist[:junk].each_with_index do |item, idx|
  @filelist[:junk][idx][:delete] = true
end

puts "--*Listview Junk FileList*-----------------------------------------"
%W{junk}.each do |key|
  puts "@filelist[:#{key}]:"
  @filelist[key.to_sym].each do |item|
    # p item
    if item[:delete] == true
      puts "basename: #{item[:basename]}"
    end
  end
end

puts "--*Delete Junk File*-----------------------------------------"
# 続行判定
puts "junkfile delete continue?(y/n): "
@flag = STDIN.gets.chomp
if @flag != "y"
  puts "input: #{@flag}, Bye!"
  exit
end

# 削除処理@ジャンクファイル
%W{junk}.each do |key|
  @filelist[key.to_sym].each do |item|
    # p item
    if item[:delete] == true
      puts %Q{rm "#{item[:filepath]}"}
      %x{rm "#{item[:filepath]}"}
    end
  end
end

puts "--*Listview mov, img FileList*-----------------------------------------"
%W{mov img}.each do |key|
  puts "@filelist[:#{key}]:"
  @filelist[key.to_sym].each do |item|
    # p item
    if item[:delete] == true
      puts "basename: #{item[:basename]}"
    end
  end
end

puts "--*Copy mov, img PreviewFile*-----------------------------------------"
# *削除対象ファイルをコピー
puts "copy continue?(y/n): "
@flag = STDIN.gets.chomp
if @flag == "y"
  # *削除対象ファイルをコピー
  puts "@tmp_files_directory: #{@tmp_files_directory}"
  %W{mov img}.each do |key|
    @filelist[key.to_sym].each do |item|
      # p item
      if item[:delete] == true
        puts %Q{cp "#{item[:filepath]}" "#{@tmp_files_directory}"}
        %x{cp "#{item[:filepath]}" "#{@tmp_files_directory}"}
      end
    end
  end
# elsif @flag == "t"
  #threw
else
  puts "input: #{@flag}, Bye!"
  exit
end

puts "--*Delete mov, img Preview+RealFile*-----------------------------------------"
# 続行判定
puts "delete continue?(y/n): "
@flag = STDIN.gets.chomp
if @flag != "y"
  puts "input: #{@flag}, Bye!"
  exit
end

# 削除処理@実ファイル
%W{mov img junk}.each do |key|
  @filelist[key.to_sym].each do |item|
    # p item
    if item[:delete] == true
      puts %Q{rm "#{item[:filepath]}"}
      %x{rm "#{item[:filepath]}"}
    end
  end
end
# 削除処理@プレビューファイル
%W{mov img junk}.each do |key|
  @filelist[key.to_sym].each do |item|
    # p item
    if item[:delete] == true
      puts %Q{rm "#{@tmp_files_directory}/#{item[:basename]}"}
      %x{rm "#{@tmp_files_directory}/#{item[:basename]}"}
    end
  end
end
