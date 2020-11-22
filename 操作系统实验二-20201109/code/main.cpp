#include <iostream>
#include <cstdio>
#include <cstring>
#include <unistd.h>
#include <vector>
#include <stack>
#include <string>
#include <algorithm>
#include <queue>
using namespace std;

const int IMAGE_SIZE = 1440 * 1024;
const int NORMAL_FILE = 0x20;
const int DIR_FILE = 0x10;

extern "C" {
    void my_putchar (const char);
    void my_puts (const char*);
    void my_print (const char*, const int);
}

int char2int (const char* const source, int begin, int size) {
    int tmp = 0;
    for (int i = begin + size - 1; i >= begin; --i) {
        tmp = tmp * 256 + (unsigned char) source[i];
    }
    return tmp;
}

void print_int (const int n) {
    if (n == 0) {
        my_putchar('0');
        return;
    }
    stack<char> s;
    int t = n;
    while (t) {
        s.push('0' + t % 10);
        t /= 10;
    }
    while (!s.empty()) {
        my_putchar(s.top());
        s.pop();
    }
}

void splitPath (const string path, vector<string>* const paths) {
    paths->clear();
    string tmp = "";
    for (char ch : path) {
        if (ch == '/') {
            if (tmp.size() > 0) {
                paths->push_back(tmp);
                tmp.clear();
            }
        }
        else {
            tmp += ch;
        }
    }
    paths->push_back(tmp);
}

bool FileNameCompare (const char* const name1, string name2) {
    if (name2.size() > 12) return false;
    int pos = name2.find_last_of('.');
    if (pos == (int) string::npos) {
        while (name2.size() < 11) {
            name2 += ' ';
        }
    }
    else {
        string tmp = "";
        for (int i = 0; i < pos; ++i) {
            tmp += name2[i];
        }
        while (tmp.size() < 8) {
            tmp += ' ';
        }
        for (size_t i = pos + 1; i < name2.size(); ++i) {
            tmp += name2[i];
        }
        while (tmp.size() < 11) {
            tmp += ' ';
        }
        name2 = tmp;
    }
    for (int i = 0; i < 11; ++i) {
        if (!(name1[i] == name2[i])) {
            return false;
        }
    }
    return true;
}

struct FileEntry {
    char DIR_Name[11];
    // char DIR_Name[8];
    // char DIR_Name_Ext[3];
    char DIR_Attr[1];
    char preserved[10];
    char DIR_WrtTime[2];
    char DIR_WrtDate[2];
    char DIR_FstClus[2];
    char DIR_FileSize[4];
};

class Fat12Reader {
private:
    char data[IMAGE_SIZE];
    int BPB_BytePerSec;
    int BPB_RootEntCnt;
    int Fat1StartSector;
    int Fat2StartSector;
    int FatSectors;
    int RootDirStartSector;
    int RootDirSectors;
    int DataStartSector;
    int DataSectors;
public:
    int rootEntryNum;
    vector<FileEntry> rootEntries;
    void readData (char* const target, const int secNum, const int begin, const int size) {
        for (int i = 0 ; i < size; ++i) {
            target[i] = data[secNum * BPB_BytePerSec + begin + i];
        }
    }
    void readClus (char* const target, const int clusNum) {
        readData(target, DataStartSector + clusNum - 2, 0, BPB_BytePerSec);
    }
    int readFat (const int clus) {
        char buf[2];
        readData(buf, Fat1StartSector, clus * 3 / 2, 2);
        int newClus = clus % 2 ? (((unsigned char) buf[1]) * 16 + ((unsigned char) buf[0]) / 16) : (((unsigned char) buf[1]) % 16 * 256 + ((unsigned char) buf[0]));
        if (newClus >= 0xff7 || newClus <= 1) {
            newClus = 0;
        }
        return newClus;
    }
    void invalidImage () {
        my_puts("不是一个合法的 FAT12 1.44M 软盘文件，程序退出！");
        exit(-1);
    }
    Fat12Reader (const char* const imgPath) {
        FILE *fp = fopen(imgPath, "r");
        if (!fp) {
            invalidImage();
        }
        int count = fread(data, IMAGE_SIZE, 1, fp);
        fclose(fp);
        if (count != 1) {
            invalidImage();
        }

        char buf[512];
        readData(buf, 0, 0, 512);
        BPB_BytePerSec = char2int(buf, 11, 2);
        BPB_RootEntCnt = char2int(buf, 17, 2);
        int flag = char2int(buf, 510, 2);
        if (flag != 0xaa55) {
            invalidImage();
        }
        FatSectors = 9;
        Fat1StartSector = 1;
        Fat2StartSector = Fat1StartSector + FatSectors;
        RootDirStartSector = Fat2StartSector + FatSectors;
        RootDirSectors = ((BPB_RootEntCnt * sizeof(FileEntry)) + (BPB_BytePerSec - 1)) / BPB_BytePerSec;
        DataStartSector = RootDirStartSector + RootDirSectors;
        DataSectors = IMAGE_SIZE / BPB_BytePerSec - DataStartSector;

        for (int i = 0; i < BPB_RootEntCnt; ++i) {
            char buf[sizeof(FileEntry)];
            readData(buf, RootDirStartSector, i * sizeof(FileEntry), sizeof(FileEntry));
            FileEntry rootEntry;
            memcpy(&rootEntry, buf, sizeof(FileEntry));
            int attr = char2int(rootEntry.DIR_Attr, 0, sizeof rootEntry.DIR_Attr);
            if (rootEntry.DIR_Name[0] <= 0 || (attr != NORMAL_FILE && attr != DIR_FILE)) continue;
            rootEntries.push_back(rootEntry);
        }
        rootEntryNum = rootEntries.size();
    }
    int getFileEntry (const string path, vector<FileEntry>* const fileEntries) {
        if (!fileEntries) return 0;
        fileEntries->clear();
        for (FileEntry rootEntry : rootEntries) {
            fileEntries->push_back(rootEntry);
        }
        if (path == "/") {
            return DIR_FILE;
        }
        vector<string> paths;
        splitPath(path, &paths);
        for (size_t i = 0; i < paths.size(); ++i) {
            string dirName = paths[i];
            if (dirName.size() == 0) {
                break;
            }
            FileEntry* entry = nullptr;
            for (FileEntry fileEntry : *fileEntries) {
                if (FileNameCompare(fileEntry.DIR_Name, dirName)) {
                    entry = &fileEntry;
                    break;
                }
            }
            fileEntries->clear();
            if (entry == nullptr) return 0;
            int attr = char2int(entry->DIR_Attr, 0, sizeof entry->DIR_Attr);
            if (i + 1 == paths.size() && attr == NORMAL_FILE) {
                fileEntries->push_back(*entry);
                return NORMAL_FILE;
            }
            if (attr == DIR_FILE) {
                int nextClus = char2int(entry->DIR_FstClus, 0, sizeof entry->DIR_FstClus);
                char buf[BPB_BytePerSec];
                while (nextClus > 0) {
                    readClus(buf, nextClus);
                    nextClus = readFat(nextClus);
                    for (unsigned int i = 0; i < BPB_BytePerSec / sizeof(FileEntry); ++i) {
                        FileEntry entry;
                        memcpy(&entry, buf + i * sizeof(FileEntry), sizeof(FileEntry));
                        int attr = char2int(entry.DIR_Attr, 0, sizeof entry.DIR_Attr);
                        if (entry.DIR_Name[0] <= 0 || (attr != NORMAL_FILE && attr != DIR_FILE)) continue;
                        fileEntries->push_back(entry);
                    }
                }
            }
            else {
                return 0;
            }
        }
        return DIR_FILE;
    }
    int readFile (const string path, string* const content) {
        vector<FileEntry> fileEntries;
        if (!getFileEntry(path, &fileEntries)) {
            return 0;
        }
        if (fileEntries.size() != 1) {
            return DIR_FILE;
        }
        FileEntry &fileEntry = fileEntries[0];
        int attr = char2int(fileEntry.DIR_Attr, 0, sizeof fileEntry.DIR_Attr);
        if (attr != NORMAL_FILE) {
            return DIR_FILE;
        }
        *content = "";
        int fileSize = char2int(fileEntry.DIR_FileSize, 0, sizeof fileEntry.DIR_FileSize);
        int nextClus = char2int(fileEntry.DIR_FstClus, 0, sizeof fileEntry.DIR_FstClus);
        char buf[BPB_BytePerSec];
        while (nextClus > 0) {
            readClus(buf, nextClus);
            nextClus = readFat(nextClus);
            for (int i = 0; i < BPB_BytePerSec && fileSize; ++i, --fileSize) {
                *content += buf[i];
            }
        }
        return NORMAL_FILE;
    }
} fat12Reader("./a.img");

string makeUpPath (string s) {
    while (s.find("//") != string::npos) {
        s = s.replace(s.find("//"), 2, "/");
    }
    if (s[0] != '/') s = "/" + s;
    return s;
}

string getFileName (const char* const fileName) {
    char buf[12];
    memcpy(buf, fileName, 11);
    buf[11] = '\0';
    string s(buf);
    string name = s.substr(0, 8), ext = s.substr(8, 3);
    while (name.size() > 0 && name[name.size() - 1] == ' ') name = name.substr(0, name.size() - 1);
    while (ext.size() > 0 && ext[ext.size() - 1] == ' ') ext = ext.substr(0, ext.size() - 1);
    if (ext.size() > 0) return name + "." + ext;
    return name;
}

bool isRelative (const char* const path) {
    return getFileName(path) == "." || getFileName(path) == "..";
}

void printFileCount (const string path) {
    vector<FileEntry> fileEntries;
    fat12Reader.getFileEntry(path.c_str(), &fileEntries);
    int normalCount = 0, dirCount = 0;
    for (FileEntry fileEntry : fileEntries) {
        int attr = char2int(fileEntry.DIR_Attr, 0, sizeof fileEntry.DIR_Attr);
        if (attr == DIR_FILE) {
            if (!isRelative(fileEntry.DIR_Name)) {
                dirCount++;
            }
        }
        else {
            normalCount++;
        }
    }
    my_putchar(' ');
    print_int(dirCount);
    my_putchar(' ');
    print_int(normalCount);
}

bool parseCommand (const string s, vector<char>* const options, vector<string>* const args) {
    options->clear();
    args->clear();
    if (s.size() == 0) {
        return false;
    }
    for (size_t i = 0; i < s.size(); ++i) {
        if (s[i] == '-') {
            bool flag = false;
            while(i + 1 < s.size() && s[i + 1] != ' ') {
                flag = true;
                options->push_back(s[i + 1]);
                i++;
            }
            if (!flag) {
                args->push_back("-");
            }
        }
        else if (s[i] != ' ') {
            string tmp = "";
            tmp += s[i];
            while (i + 1 < s.size() && s[i + 1] != ' ') {
                tmp += s[i + 1];
                i++;
            }
            args->push_back(tmp);
        }
    }
    sort(options->begin(), options->end());
    options->resize(unique(options->begin(), options->end()) - options->begin());
    if (args->size() == 0) {
        return false;
    }
    return true;
}

void redStart () {
    my_puts("\033[31m");
}

void redEnd () {
    my_puts("\033[0m");
}

int main () {
    string command;
    vector<char> options;
    vector<string> args;
    while (true) {
        my_puts("> ");
        if (!getline(cin, command)) break;
        if (!parseCommand(command, &options, &args)) {
            my_puts("请输入一个命令！\n");
            continue;
        }
        if (args[0] == "exit") {
            if (options.size() == 0) {
                if (args.size() == 1) {
                    break;
                }
                else {
                    my_puts("exit 不能有参数哦！\n");
                }
            }
            else {
                my_puts("exit 不能有选项哦！\n");
            }
        }
        else if (args[0] == "cat") {
            if (options.size() == 0) {
                if (args.size() == 2) {
                    string path = makeUpPath(args[1]);
                    string content;
                    int res = fat12Reader.readFile(path, &content);
                    if (!res) {
                        my_puts(path.c_str());
                        my_puts(" 文件不存在！\n");
                    }
                    else if (res == DIR_FILE) {
                        my_puts(path.c_str());
                        my_puts(" 是一个目录文件！\n");
                    }
                    else {
                        my_puts(content.c_str());
                    }
                }
                else {
                    my_puts("cat 要且仅要一个参数哦！\n");
                }
            }
            else {
                my_puts("cat 不能有选项哦！\n");
            }
        }
        else if (args[0] == "ls") {
            if (options.size() > 1 || (options.size() == 1 && options[0] != 'l')) {
                my_puts("这些选项俺不认识：");
                for (char option : options) {
                    if (option != 'l') {
                        my_puts(" -");
                        my_putchar(option);
                    }
                }
                my_putchar('\n');
            }
            else if (args.size() > 2) {
                my_puts("ls 最多只要一个参数哦！\n");
            }
            else {
                string path = makeUpPath((args.size() == 1 ? "" : args[1]) + "/");
                bool flag = options.size() == 1;
                vector<FileEntry> fileEntries;
                if (!fat12Reader.getFileEntry(path, &fileEntries)) {
                    my_puts(path.c_str());
                    my_puts(" 文件不存在！\n");
                }
                else {
                    queue<string> paths;
                    paths.push(path);
                    while (!paths.empty()) {
                        path = paths.front();
                        paths.pop();
                        my_puts(path.c_str());
                        fat12Reader.getFileEntry(path, &fileEntries);
                        if (flag) {
                            printFileCount(path);
                        }
                        my_puts(":\n");
                        for (FileEntry fileEntry : fileEntries) {
                            int attr = char2int(fileEntry.DIR_Attr, 0, sizeof fileEntry.DIR_Attr);
                            if (attr == DIR_FILE) {
                                if (flag) {
                                    redStart();
                                    my_puts(getFileName(fileEntry.DIR_Name).c_str());
                                    redEnd();
                                    if (!isRelative(fileEntry.DIR_Name)) {
                                        printFileCount(path + getFileName(fileEntry.DIR_Name) + "/");
                                    }
                                    my_putchar('\n');
                                }
                                else {
                                    redStart();
                                    my_puts(getFileName(fileEntry.DIR_Name).c_str());
                                    redEnd();
                                    my_puts("  ");
                                }
                                if (!isRelative(fileEntry.DIR_Name)) {
                                    paths.push(path + getFileName(fileEntry.DIR_Name) + "/");
                                }
                            }
                            else {
                                if (flag) {
                                    my_puts(getFileName(fileEntry.DIR_Name).c_str());
                                    my_putchar(' ');
                                    print_int(char2int(fileEntry.DIR_FileSize, 0, sizeof fileEntry.DIR_FileSize));
                                    my_putchar('\n');
                                }
                                else {
                                    my_puts(getFileName(fileEntry.DIR_Name).c_str());
                                    my_puts("  ");
                                }
                            }
                        }
                        my_putchar('\n');
                    }
                }
                
            }
        }
        else {
            my_puts(args[0].c_str());
            my_puts(" ");
            my_puts("这个指令俺不认识呀！\n");
        }
    }
    my_puts("拜拜了哦！\n");
    return 0;
}
