import brut.androlib.smali.SmaliBuilder;
import com.android.tools.smali.dexlib2.Opcodes;
import com.android.tools.smali.dexlib2.writer.builder.DexBuilder;
import com.android.tools.smali.dexlib2.writer.io.FileDataStore;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;

class AssembleSpaceDex {
    public static void main(String[] args) throws Exception {
        int api = args.length > 2 ? Integer.parseInt(args[2]) : 24;
        DexBuilder dex = new DexBuilder(new Opcodes(api));
        SmaliBuilder assembler = new SmaliBuilder(api);
        try (Stream<Path> input = Files.walk(Path.of(args[0]))) {
            for (Path path : input.filter(p -> p.toString().endsWith(".smali")).sorted().toList()) {
                if (!assembler.buildFile(path.toFile(), dex))
                    throw new IllegalStateException("Unable to assemble " + path);
            }
        }
        FileDataStore out = new FileDataStore(Path.of(args[1]).toFile());
        try { dex.writeTo(out); } finally { out.raf.close(); }
    }
}
